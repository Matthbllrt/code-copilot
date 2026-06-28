import React, { useState, useEffect, useCallback } from 'react';
import {
  View, Text, TouchableOpacity, TextInput, StyleSheet,
  ScrollView, ActivityIndicator, Alert, Share, Modal,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc,
  arrayUnion, arrayRemove, collection, query, where, getDocs,
} from 'firebase/firestore';
import * as Haptics from 'expo-haptics';

import { db, getCurrentUser } from '../firebase';
import { COLORS, SPACING, RADIUS } from '../theme';

const MAX_CIRCLES = 5;

function generateCode(length = 6) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < length; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

function getTodayKey() {
  return new Date().toISOString().split('T')[0];
}

export default function CirclesScreen() {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [circles, setCircles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null); // 'create' | 'join' | null
  const [input, setInput] = useState('');
  const [working, setWorking] = useState(false);

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        const u = await getCurrentUser();
        if (!mounted) return;
        setUser(u);
        await loadAll(u.uid, mounted);
      } catch {
        if (mounted) setLoading(false);
      }
    })();
    return () => { mounted = false; };
  }, []);

  const loadAll = async (uid, mounted = true) => {
    try {
      const snap = await getDoc(doc(db, 'users', uid));
      if (!snap.exists() || !mounted) return;
      const p = snap.data();
      setProfile(p);
      await loadCircles(p.circles ?? [], mounted);
    } catch (e) {
      console.warn('CirclesScreen loadAll error:', e);
    } finally {
      if (mounted) setLoading(false);
    }
  };

  const loadCircles = async (circleIds, mounted = true) => {
    if (!circleIds.length) return;
    const today = getTodayKey();
    try {
      const results = await Promise.all(
        circleIds.map(async (id) => {
          const snap = await getDoc(doc(db, 'circles', id)).catch(() => null);
          if (!snap?.exists()) return null;
          const data = snap.data();

          // Fetch members' votes for today
          let votesA = 0, votesB = 0, voted = 0;
          await Promise.all(
            (data.members ?? []).map(async (uid) => {
              const uSnap = await getDoc(doc(db, 'users', uid)).catch(() => null);
              if (!uSnap?.exists()) return;
              const u = uSnap.data();
              if (u.lastVoteDate === today) {
                voted++;
                if (u.lastVoteChoice === 'A') votesA++;
                else if (u.lastVoteChoice === 'B') votesB++;
              }
            })
          );

          return { id, ...data, votesA, votesB, voted };
        })
      );
      if (mounted) setCircles(results.filter(Boolean));
    } catch {}
  };

  const handleCreate = async () => {
    const name = input.trim();
    if (!name) { Alert.alert('Nom requis', 'Donne un nom à ton cercle.'); return; }
    if (!user) return;

    const currentCircles = profile?.circles ?? [];
    if (currentCircles.length >= MAX_CIRCLES) {
      Alert.alert('Maximum atteint', `Tu ne peux rejoindre que ${MAX_CIRCLES} cercles au maximum.`);
      return;
    }

    setWorking(true);
    try {
      const circleId = `c_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
      const code = generateCode(6);
      const circleData = {
        name,
        code,
        ownerUid: user.uid,
        members: [user.uid],
        createdAt: new Date(),
      };
      await setDoc(doc(db, 'circles', circleId), circleData);
      await setDoc(doc(db, 'circleCodes', code), { circleId });
      await updateDoc(doc(db, 'users', user.uid), { circles: arrayUnion(circleId) });

      try { await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success); } catch {}
      setModal(null);
      setInput('');
      await loadAll(user.uid);
    } catch (e) {
      console.warn('handleCreate error:', e);
      Alert.alert('Erreur', 'Impossible de créer le cercle. Réessaie.');
    } finally {
      setWorking(false);
    }
  };

  const handleJoin = async () => {
    const code = input.trim().toUpperCase();
    if (code.length !== 6) { Alert.alert('Code invalide', 'Le code cercle est composé de 6 caractères.'); return; }
    if (!user) return;

    const currentCircles = profile?.circles ?? [];
    if (currentCircles.length >= MAX_CIRCLES) {
      Alert.alert('Maximum atteint', `Tu ne peux rejoindre que ${MAX_CIRCLES} cercles au maximum.`);
      return;
    }

    setWorking(true);
    try {
      const codeSnap = await getDoc(doc(db, 'circleCodes', code));
      if (!codeSnap.exists()) {
        Alert.alert('Code introuvable', 'Aucun cercle avec ce code.');
        return;
      }
      const { circleId } = codeSnap.data();
      if (currentCircles.includes(circleId)) {
        Alert.alert('Déjà membre', 'Tu fais déjà partie de ce cercle.');
        return;
      }

      await updateDoc(doc(db, 'circles', circleId), { members: arrayUnion(user.uid) });
      await updateDoc(doc(db, 'users', user.uid), { circles: arrayUnion(circleId) });

      try { await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success); } catch {}
      setModal(null);
      setInput('');
      await loadAll(user.uid);
    } catch (e) {
      console.warn('handleJoin error:', e);
      Alert.alert('Erreur', 'Impossible de rejoindre le cercle. Réessaie.');
    } finally {
      setWorking(false);
    }
  };

  const handleLeave = (circle) => {
    const isOwner = circle.ownerUid === user?.uid;
    Alert.alert(
      isOwner ? 'Supprimer ce cercle ?' : 'Quitter ce cercle ?',
      isOwner
        ? 'En tant qu\'admin, quitter supprime le cercle pour tous les membres.'
        : 'Tu ne verras plus les réponses de ce groupe.',
      [
        { text: 'Annuler', style: 'cancel' },
        {
          text: isOwner ? 'Supprimer' : 'Quitter',
          style: 'destructive',
          onPress: async () => {
            if (!user) return;
            try {
              if (isOwner) {
                await deleteDoc(doc(db, 'circles', circle.id));
                await deleteDoc(doc(db, 'circleCodes', circle.code)).catch(() => {});
                await Promise.all(
                  (circle.members ?? []).map((uid) =>
                    updateDoc(doc(db, 'users', uid), { circles: arrayRemove(circle.id) }).catch(() => {})
                  )
                );
              } else {
                await updateDoc(doc(db, 'circles', circle.id), { members: arrayRemove(user.uid) });
                await updateDoc(doc(db, 'users', user.uid), { circles: arrayRemove(circle.id) });
              }
              await loadAll(user.uid);
            } catch {}
          },
        },
      ]
    );
  };

  const shareCircle = useCallback(async (circle) => {
    try {
      await Share.share({
        message: `Rejoins mon cercle « ${circle.name} » sur Cercle !\nCode : ${circle.code} 👥`,
        title: `Rejoins ${circle.name}`,
      });
    } catch {}
  }, []);

  if (loading) {
    return (
      <View style={s.center}>
        <ActivityIndicator color={COLORS.ember} size="large" />
      </View>
    );
  }

  return (
    <SafeAreaView style={s.container} edges={['top']}>
      <ScrollView contentContainerStyle={s.scroll} showsVerticalScrollIndicator={false}>

        <View style={s.headerRow}>
          <Text style={s.screenTitle}>Cercles</Text>
          <Text style={s.circleCount}>{circles.length}/{MAX_CIRCLES}</Text>
        </View>
        <Text style={s.subtitle}>Groupes privés · max 5</Text>

        {/* Action buttons */}
        <View style={s.actionRow}>
          <TouchableOpacity
            style={[s.actionBtn, circles.length >= MAX_CIRCLES && s.actionBtnDisabled]}
            onPress={() => { setInput(''); setModal('create'); }}
            disabled={circles.length >= MAX_CIRCLES}
            activeOpacity={0.8}
          >
            <Text style={s.actionBtnText}>+ Créer</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[s.actionBtn, s.actionBtnAlt, circles.length >= MAX_CIRCLES && s.actionBtnDisabled]}
            onPress={() => { setInput(''); setModal('join'); }}
            disabled={circles.length >= MAX_CIRCLES}
            activeOpacity={0.8}
          >
            <Text style={[s.actionBtnText, { color: COLORS.mint }]}>Rejoindre</Text>
          </TouchableOpacity>
        </View>

        {/* Circles list */}
        {circles.length === 0 ? (
          <View style={s.emptyState}>
            <Text style={s.emptyEmoji}>👥</Text>
            <Text style={s.emptyText}>Aucun cercle</Text>
            <Text style={s.emptySubtext}>Crée ou rejoins un groupe pour comparer vos réponses !</Text>
          </View>
        ) : (
          circles.map((c) => (
            <CircleCard
              key={c.id}
              circle={c}
              isOwner={c.ownerUid === user?.uid}
              onLeave={() => handleLeave(c)}
              onShare={() => shareCircle(c)}
            />
          ))
        )}
      </ScrollView>

      {/* Modal create/join */}
      <Modal
        visible={modal !== null}
        transparent
        animationType="slide"
        onRequestClose={() => { setModal(null); setInput(''); }}
      >
        <View style={s.modalOverlay}>
          <View style={s.modalCard}>
            <Text style={s.modalTitle}>
              {modal === 'create' ? 'Créer un cercle' : 'Rejoindre un cercle'}
            </Text>
            <TextInput
              style={s.modalInput}
              value={input}
              onChangeText={modal === 'join' ? (t) => setInput(t.toUpperCase()) : setInput}
              placeholder={modal === 'create' ? 'Nom du cercle' : 'Code à 6 caractères'}
              placeholderTextColor={COLORS.textDim}
              maxLength={modal === 'create' ? 30 : 6}
              autoCapitalize={modal === 'join' ? 'characters' : 'words'}
              autoCorrect={false}
              autoFocus
            />
            <View style={s.modalActions}>
              <TouchableOpacity
                style={s.modalCancel}
                onPress={() => { setModal(null); setInput(''); }}
              >
                <Text style={s.modalCancelText}>Annuler</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[s.modalConfirm, working && s.modalConfirmDisabled]}
                onPress={modal === 'create' ? handleCreate : handleJoin}
                disabled={working}
              >
                {working ? (
                  <ActivityIndicator color={COLORS.background} size="small" />
                ) : (
                  <Text style={s.modalConfirmText}>{modal === 'create' ? 'Créer' : 'Rejoindre'}</Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

function CircleCard({ circle, isOwner, onLeave, onShare }) {
  const total = (circle.votesA || 0) + (circle.votesB || 0);
  const pctA = total > 0 ? Math.round(((circle.votesA || 0) / total) * 100) : 0;
  const pctB = 100 - pctA;
  const memberCount = (circle.members ?? []).length;

  return (
    <View style={s.circleCard}>
      <View style={s.circleHeader}>
        <View style={s.circleLeft}>
          <Text style={s.circleName}>{circle.name}</Text>
          <Text style={s.circleMeta}>
            {memberCount} membre{memberCount > 1 ? 's' : ''} · Code : {circle.code}
            {isOwner ? ' · 👑 Admin' : ''}
          </Text>
        </View>
        <View style={s.circleActions}>
          <TouchableOpacity onPress={onShare} style={s.circleActionBtn}>
            <Text style={s.circleActionText}>📤</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={onLeave} style={s.circleActionBtn}>
            <Text style={s.circleActionText}>{isOwner ? '🗑' : '🚪'}</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Today's group votes */}
      {circle.voted > 0 ? (
        <View style={s.circleVotes}>
          <Text style={s.circleVotesLabel}>
            Aujourd'hui : {circle.voted}/{memberCount} ont voté
          </Text>
          <View style={s.miniBarRow}>
            <Text style={s.miniBarLabel}>A {pctA}%</Text>
            <View style={s.miniBarTrack}>
              <View style={[s.miniBarFillA, { width: `${pctA}%` }]} />
            </View>
          </View>
          <View style={s.miniBarRow}>
            <Text style={s.miniBarLabel}>B {pctB}%</Text>
            <View style={s.miniBarTrack}>
              <View style={[s.miniBarFillB, { width: `${pctB}%` }]} />
            </View>
          </View>
        </View>
      ) : (
        <Text style={s.circleNoVote}>Personne n'a encore voté aujourd'hui</Text>
      )}
    </View>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  center: { flex: 1, backgroundColor: COLORS.background, justifyContent: 'center', alignItems: 'center' },
  scroll: { padding: SPACING.md, paddingBottom: SPACING.xxl },

  headerRow: { flexDirection: 'row', alignItems: 'baseline', gap: SPACING.sm, marginBottom: 4 },
  screenTitle: { color: COLORS.text, fontSize: 28, fontFamily: 'Fraunces_700Bold' },
  circleCount: { color: COLORS.textMuted, fontSize: 16, fontFamily: 'Inter_400Regular' },
  subtitle: { color: COLORS.textDim, fontSize: 13, fontFamily: 'Inter_400Regular', marginBottom: SPACING.lg },

  actionRow: { flexDirection: 'row', gap: SPACING.sm, marginBottom: SPACING.lg },
  actionBtn: {
    flex: 1,
    backgroundColor: COLORS.ember,
    borderRadius: RADIUS.md,
    paddingVertical: 12,
    alignItems: 'center',
  },
  actionBtnAlt: { backgroundColor: COLORS.mint + '22', borderWidth: 1, borderColor: COLORS.mint },
  actionBtnDisabled: { opacity: 0.4 },
  actionBtnText: { color: COLORS.background, fontFamily: 'Inter_700Bold', fontSize: 15 },

  emptyState: { padding: SPACING.xxl, alignItems: 'center', gap: SPACING.sm },
  emptyEmoji: { fontSize: 48 },
  emptyText: { color: COLORS.text, fontSize: 18, fontFamily: 'Fraunces_700Bold' },
  emptySubtext: { color: COLORS.textMuted, fontSize: 14, fontFamily: 'Inter_400Regular', textAlign: 'center' },

  circleCard: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    marginBottom: SPACING.md,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  circleHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: SPACING.sm },
  circleLeft: { flex: 1 },
  circleName: { color: COLORS.text, fontSize: 17, fontFamily: 'Inter_700Bold' },
  circleMeta: { color: COLORS.textMuted, fontSize: 12, fontFamily: 'Inter_400Regular', marginTop: 2 },
  circleActions: { flexDirection: 'row', gap: 8 },
  circleActionBtn: { padding: 6 },
  circleActionText: { fontSize: 18 },

  circleVotes: { marginTop: SPACING.sm, gap: 6 },
  circleVotesLabel: { color: COLORS.textMuted, fontSize: 12, fontFamily: 'Inter_400Regular', marginBottom: 4 },
  miniBarRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  miniBarLabel: { color: COLORS.textMuted, fontSize: 12, fontFamily: 'Inter_600SemiBold', width: 48 },
  miniBarTrack: { flex: 1, height: 6, backgroundColor: COLORS.border, borderRadius: 3, overflow: 'hidden' },
  miniBarFillA: { height: '100%', backgroundColor: COLORS.ember, borderRadius: 3 },
  miniBarFillB: { height: '100%', backgroundColor: COLORS.mint, borderRadius: 3 },
  circleNoVote: { color: COLORS.textDim, fontSize: 13, fontFamily: 'Inter_400Regular', marginTop: 4 },

  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.7)',
    justifyContent: 'flex-end',
  },
  modalCard: {
    backgroundColor: COLORS.surface,
    borderTopLeftRadius: RADIUS.xl,
    borderTopRightRadius: RADIUS.xl,
    padding: SPACING.lg,
    paddingBottom: SPACING.xxl,
    borderTopWidth: 1,
    borderColor: COLORS.border,
  },
  modalTitle: { color: COLORS.text, fontSize: 20, fontFamily: 'Fraunces_700Bold', marginBottom: SPACING.md },
  modalInput: {
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.md,
    paddingVertical: 14,
    color: COLORS.text,
    fontFamily: 'Inter_600SemiBold',
    fontSize: 17,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: SPACING.md,
  },
  modalActions: { flexDirection: 'row', gap: SPACING.sm },
  modalCancel: {
    flex: 1,
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.md,
    paddingVertical: 14,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  modalCancelText: { color: COLORS.textMuted, fontFamily: 'Inter_600SemiBold', fontSize: 15 },
  modalConfirm: {
    flex: 1,
    backgroundColor: COLORS.ember,
    borderRadius: RADIUS.md,
    paddingVertical: 14,
    alignItems: 'center',
  },
  modalConfirmDisabled: { opacity: 0.6 },
  modalConfirmText: { color: COLORS.background, fontFamily: 'Inter_700Bold', fontSize: 15 },
});
