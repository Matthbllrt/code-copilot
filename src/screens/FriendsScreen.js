import React, { useState, useEffect, useCallback } from 'react';
import {
  View, Text, TouchableOpacity, TextInput, StyleSheet,
  ScrollView, ActivityIndicator, Alert, Share,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  doc, getDoc, updateDoc, arrayUnion,
} from 'firebase/firestore';
import * as Haptics from 'expo-haptics';

import { db, getCurrentUser } from '../firebase';
import { COLORS, FONTS, SPACING, RADIUS } from '../theme';

function getTodayKey() {
  return new Date().toISOString().split('T')[0];
}

export default function FriendsScreen() {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [friends, setFriends] = useState([]);
  const [addCode, setAddCode] = useState('');
  const [loading, setLoading] = useState(true);
  const [adding, setAdding] = useState(false);

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        const u = await getCurrentUser();
        if (!mounted) return;
        setUser(u);
        await loadProfile(u.uid, mounted);
      } catch {
        if (mounted) setLoading(false);
      }
    })();
    return () => { mounted = false; };
  }, []);

  const loadProfile = async (uid, mounted = true) => {
    try {
      const snap = await getDoc(doc(db, 'users', uid));
      if (!snap.exists() || !mounted) return;
      const p = snap.data();
      setProfile(p);
      await loadFriends(p.friends ?? [], mounted);
    } catch (e) {
      console.warn('FriendsScreen loadProfile error:', e);
    } finally {
      if (mounted) setLoading(false);
    }
  };

  const loadFriends = async (friendUids, mounted = true) => {
    if (!friendUids.length) return;
    const today = getTodayKey();
    try {
      const results = await Promise.all(
        friendUids.slice(0, 20).map(async (uid) => {
          const snap = await getDoc(doc(db, 'users', uid)).catch(() => null);
          if (!snap?.exists()) return null;
          const d = snap.data();
          return {
            uid,
            name: d.displayName || 'Ami',
            friendCode: d.friendCode,
            votedToday: d.lastVoteDate === today,
            choice: d.lastVoteChoice,
            streak: d.streak || 0,
          };
        })
      );
      if (mounted) setFriends(results.filter(Boolean));
    } catch {}
  };

  const handleAddFriend = async () => {
    const code = addCode.trim().toUpperCase();
    if (code.length !== 6) {
      Alert.alert('Code invalide', 'Le code ami est composé de 6 caractères.');
      return;
    }
    if (!user) return;
    setAdding(true);
    try { await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); } catch {}

    try {
      const codeSnap = await getDoc(doc(db, 'friendCodes', code));
      if (!codeSnap.exists()) {
        Alert.alert('Code introuvable', 'Aucun utilisateur avec ce code. Vérifie avec ton ami.');
        return;
      }
      const friendUid = codeSnap.data().uid;
      if (friendUid === user.uid) {
        Alert.alert('Oups', 'Tu ne peux pas t\'ajouter toi-même 😄');
        return;
      }
      if ((profile?.friends ?? []).includes(friendUid)) {
        Alert.alert('Déjà ami', 'Cet utilisateur est déjà dans ta liste d\'amis.');
        return;
      }

      await updateDoc(doc(db, 'users', user.uid), {
        friends: arrayUnion(friendUid),
      });

      setAddCode('');
      await loadProfile(user.uid);
      try { await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success); } catch {}
      Alert.alert('Ami ajouté ! 🤝', 'Tu peux maintenant voir ses réponses chaque jour.');
    } catch (e) {
      console.warn('handleAddFriend error:', e);
      Alert.alert('Erreur', 'Impossible d\'ajouter cet ami. Réessaie.');
    } finally {
      setAdding(false);
    }
  };

  const handleRemoveFriend = (friendUid) => {
    Alert.alert(
      'Retirer cet ami ?',
      'Tu ne verras plus ses réponses quotidiennes.',
      [
        { text: 'Annuler', style: 'cancel' },
        {
          text: 'Retirer',
          style: 'destructive',
          onPress: async () => {
            if (!user) return;
            try {
              const newFriends = (profile?.friends ?? []).filter((u) => u !== friendUid);
              await updateDoc(doc(db, 'users', user.uid), { friends: newFriends });
              await loadProfile(user.uid);
            } catch {}
          },
        },
      ]
    );
  };

  const shareCode = useCallback(async () => {
    if (!profile?.friendCode) return;
    try {
      await Share.share({
        message: `Rejoins-moi sur Cercle ! Mon code ami : ${profile.friendCode}\nUne question piquante par jour 🔥`,
        title: 'Rejoins mon Cercle',
      });
    } catch {}
  }, [profile]);

  if (loading) {
    return (
      <View style={s.center}>
        <ActivityIndicator color={COLORS.ember} size="large" />
      </View>
    );
  }

  const today = getTodayKey();

  return (
    <SafeAreaView style={s.container} edges={['top']}>
      <ScrollView contentContainerStyle={s.scroll} showsVerticalScrollIndicator={false}>

        <Text style={s.screenTitle}>Amis</Text>

        {/* My code */}
        <View style={s.myCodeCard}>
          <Text style={s.myCodeLabel}>Mon code ami</Text>
          <Text style={s.myCode}>{profile?.friendCode || '------'}</Text>
          <Text style={s.myCodeHint}>Partage ce code pour qu'on te retrouve</Text>
          <TouchableOpacity style={s.shareBtn} onPress={shareCode} activeOpacity={0.8}>
            <Text style={s.shareBtnText}>Partager mon code 📤</Text>
          </TouchableOpacity>
        </View>

        {/* Add friend */}
        <View style={s.addSection}>
          <Text style={s.sectionTitle}>Ajouter un ami</Text>
          <View style={s.addRow}>
            <TextInput
              style={s.codeInput}
              value={addCode}
              onChangeText={(t) => setAddCode(t.toUpperCase())}
              placeholder="Code à 6 caractères"
              placeholderTextColor={COLORS.textDim}
              maxLength={6}
              autoCapitalize="characters"
              autoCorrect={false}
            />
            <TouchableOpacity
              style={[s.addBtn, adding && s.addBtnDisabled]}
              onPress={handleAddFriend}
              disabled={adding}
              activeOpacity={0.8}
            >
              {adding ? (
                <ActivityIndicator color={COLORS.background} size="small" />
              ) : (
                <Text style={s.addBtnText}>Ajouter</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>

        {/* Friends list */}
        <View style={s.section}>
          <Text style={s.sectionTitle}>
            Mes amis {friends.length > 0 ? `(${friends.length})` : ''}
          </Text>

          {friends.length === 0 ? (
            <View style={s.emptyState}>
              <Text style={s.emptyEmoji}>🤝</Text>
              <Text style={s.emptyText}>Pas encore d'amis</Text>
              <Text style={s.emptySubtext}>Partage ton code pour les inviter !</Text>
            </View>
          ) : (
            friends.map((f) => (
              <FriendCard
                key={f.uid}
                friend={f}
                onRemove={() => handleRemoveFriend(f.uid)}
              />
            ))
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function FriendCard({ friend, onRemove }) {
  const color = friend.choice === 'A' ? COLORS.ember : COLORS.mint;
  return (
    <View style={s.friendCard}>
      <View style={[s.friendAvatar, { borderColor: friend.votedToday ? color : COLORS.border }]}>
        <Text style={s.friendAvatarText}>{friend.name.charAt(0).toUpperCase()}</Text>
      </View>
      <View style={s.friendInfo}>
        <Text style={s.friendName}>{friend.name}</Text>
        <Text style={s.friendSub}>🔥 {friend.streak} jours</Text>
      </View>
      <View style={s.friendRight}>
        {friend.votedToday ? (
          <View style={[s.voteBadge, { backgroundColor: color + '22', borderColor: color }]}>
            <Text style={[s.voteBadgeText, { color }]}>A voté {friend.choice}</Text>
          </View>
        ) : (
          <Text style={s.notVoted}>Pas encore voté</Text>
        )}
        <TouchableOpacity onPress={onRemove} style={s.removeBtn}>
          <Text style={s.removeBtnText}>✕</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  center: { flex: 1, backgroundColor: COLORS.background, justifyContent: 'center', alignItems: 'center' },
  scroll: { padding: SPACING.md, paddingBottom: SPACING.xxl },

  screenTitle: { color: COLORS.text, fontSize: 28, fontFamily: 'Fraunces_700Bold', marginBottom: SPACING.lg },

  myCodeCard: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.lg,
    marginBottom: SPACING.lg,
    borderWidth: 1,
    borderColor: COLORS.border,
    alignItems: 'center',
  },
  myCodeLabel: { color: COLORS.textMuted, fontSize: 12, fontFamily: 'Inter_600SemiBold', letterSpacing: 1, marginBottom: 8 },
  myCode: {
    color: COLORS.ember,
    fontSize: 36,
    fontFamily: 'Fraunces_700Bold',
    letterSpacing: 6,
    marginBottom: 8,
  },
  myCodeHint: { color: COLORS.textDim, fontSize: 13, fontFamily: 'Inter_400Regular', marginBottom: SPACING.md },
  shareBtn: {
    backgroundColor: COLORS.ember,
    borderRadius: RADIUS.full,
    paddingHorizontal: 24,
    paddingVertical: 10,
  },
  shareBtnText: { color: COLORS.background, fontFamily: 'Inter_700Bold', fontSize: 14 },

  addSection: { marginBottom: SPACING.lg },
  section: { marginBottom: SPACING.lg },
  sectionTitle: { color: COLORS.text, fontSize: 16, fontFamily: 'Inter_700Bold', marginBottom: SPACING.md },

  addRow: { flexDirection: 'row', gap: SPACING.sm },
  codeInput: {
    flex: 1,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.md,
    paddingVertical: 12,
    color: COLORS.text,
    fontFamily: 'Inter_700Bold',
    fontSize: 18,
    letterSpacing: 4,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  addBtn: {
    backgroundColor: COLORS.ember,
    borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.lg,
    justifyContent: 'center',
    alignItems: 'center',
    minWidth: 90,
  },
  addBtnDisabled: { opacity: 0.6 },
  addBtnText: { color: COLORS.background, fontFamily: 'Inter_700Bold', fontSize: 14 },

  emptyState: { padding: SPACING.xl, alignItems: 'center', gap: SPACING.sm },
  emptyEmoji: { fontSize: 48 },
  emptyText: { color: COLORS.text, fontSize: 18, fontFamily: 'Fraunces_700Bold' },
  emptySubtext: { color: COLORS.textMuted, fontSize: 14, fontFamily: 'Inter_400Regular', textAlign: 'center' },

  friendCard: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.md,
    padding: SPACING.md,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: SPACING.sm,
    borderWidth: 1,
    borderColor: COLORS.border,
    gap: SPACING.md,
  },
  friendAvatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: COLORS.surfaceAlt,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    flexShrink: 0,
  },
  friendAvatarText: { color: COLORS.white, fontFamily: 'Inter_700Bold', fontSize: 18 },
  friendInfo: { flex: 1 },
  friendName: { color: COLORS.text, fontSize: 15, fontFamily: 'Inter_600SemiBold' },
  friendSub: { color: COLORS.textDim, fontSize: 12, fontFamily: 'Inter_400Regular', marginTop: 2 },
  friendRight: { alignItems: 'flex-end', gap: 6 },
  voteBadge: {
    borderRadius: RADIUS.full,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderWidth: 1,
  },
  voteBadgeText: { fontSize: 12, fontFamily: 'Inter_600SemiBold' },
  notVoted: { color: COLORS.textDim, fontSize: 12, fontFamily: 'Inter_400Regular' },
  removeBtn: { padding: 4 },
  removeBtnText: { color: COLORS.textDim, fontSize: 14 },
});
