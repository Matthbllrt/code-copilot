import React, { useState, useEffect } from 'react';
import {
  View, Text, TouchableOpacity, TextInput, StyleSheet,
  ScrollView, ActivityIndicator, Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { doc, getDoc, updateDoc } from 'firebase/firestore';
import * as Haptics from 'expo-haptics';

import { db, getCurrentUser } from '../firebase';
import { useWallet } from '../contexts/WalletContext';
import { COLORS, SPACING, RADIUS } from '../theme';

const CATEGORY_COLORS = {
  'Absurde': COLORS.mint,
  'Humour noir': COLORS.textMuted,
  'Amour & Psycho': COLORS.ember,
  'Piquant': COLORS.gold,
  'Moral': COLORS.mint,
};

export default function ProfileScreen() {
  const { tokens } = useWallet();
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [editName, setEditName] = useState(false);
  const [nameInput, setNameInput] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        const u = await getCurrentUser();
        if (!mounted) return;
        setUser(u);
        const snap = await getDoc(doc(db, 'users', u.uid));
        if (snap.exists() && mounted) {
          setProfile(snap.data());
        }
      } catch {}
      finally {
        if (mounted) setLoading(false);
      }
    })();
    return () => { mounted = false; };
  }, []);

  const handleSaveName = async () => {
    const name = nameInput.trim();
    if (!name || !user) return;
    setSaving(true);
    try {
      await updateDoc(doc(db, 'users', user.uid), { displayName: name });
      setProfile((p) => ({ ...p, displayName: name }));
      setEditName(false);
      try { await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success); } catch {}
    } catch {
      Alert.alert('Erreur', 'Impossible de modifier le pseudo.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <View style={s.center}>
        <ActivityIndicator color={COLORS.ember} size="large" />
      </View>
    );
  }

  const history = (profile?.voteHistory ?? []).slice().reverse().slice(0, 20);
  const streakMax = profile?.streak || 0;

  return (
    <SafeAreaView style={s.container} edges={['top']}>
      <ScrollView contentContainerStyle={s.scroll} showsVerticalScrollIndicator={false}>

        <Text style={s.screenTitle}>Profil</Text>

        {/* Avatar + name */}
        <View style={s.profileCard}>
          <View style={s.avatar}>
            <Text style={s.avatarText}>
              {(profile?.displayName || '?').charAt(0).toUpperCase()}
            </Text>
          </View>
          {editName ? (
            <View style={s.editNameRow}>
              <TextInput
                style={s.nameInput}
                value={nameInput}
                onChangeText={setNameInput}
                placeholder="Ton pseudo"
                placeholderTextColor={COLORS.textDim}
                maxLength={20}
                autoFocus
              />
              <TouchableOpacity
                style={s.saveBtn}
                onPress={handleSaveName}
                disabled={saving}
              >
                {saving ? (
                  <ActivityIndicator color={COLORS.background} size="small" />
                ) : (
                  <Text style={s.saveBtnText}>✓</Text>
                )}
              </TouchableOpacity>
              <TouchableOpacity
                style={s.cancelBtn}
                onPress={() => setEditName(false)}
              >
                <Text style={s.cancelBtnText}>✕</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <TouchableOpacity
              onPress={() => { setNameInput(profile?.displayName || ''); setEditName(true); }}
              style={s.nameRow}
            >
              <Text style={s.name}>{profile?.displayName || 'Joueur'}</Text>
              <Text style={s.nameEdit}> ✏️</Text>
            </TouchableOpacity>
          )}
          <Text style={s.friendCodeDisplay}>Code ami : {profile?.friendCode || '------'}</Text>
        </View>

        {/* Stats */}
        <View style={s.statsRow}>
          <StatCard emoji="🔥" label="Série" value={profile?.streak || 0} color={COLORS.ember} />
          <StatCard emoji="🪙" label="Jetons" value={tokens} color={COLORS.gold} />
          <StatCard emoji="🗳" label="Votes" value={history.length} color={COLORS.mint} />
        </View>

        {/* Vote history */}
        <Text style={s.sectionTitle}>Historique</Text>
        {history.length === 0 ? (
          <View style={s.emptyHistory}>
            <Text style={s.emptyEmoji}>📋</Text>
            <Text style={s.emptyText}>Aucun vote pour l'instant</Text>
            <Text style={s.emptySubtext}>Vote chaque jour pour remplir ton historique.</Text>
          </View>
        ) : (
          history.map((entry, i) => (
            <HistoryCard key={`${entry.date}_${i}`} entry={entry} />
          ))
        )}

      </ScrollView>
    </SafeAreaView>
  );
}

function StatCard({ emoji, label, value, color }) {
  return (
    <View style={[s.statCard, { borderColor: color + '40' }]}>
      <Text style={s.statEmoji}>{emoji}</Text>
      <Text style={[s.statValue, { color }]}>{value}</Text>
      <Text style={s.statLabel}>{label}</Text>
    </View>
  );
}

function HistoryCard({ entry }) {
  const color = CATEGORY_COLORS[entry.category] || COLORS.textMuted;
  const date = entry.date ? new Date(entry.date + 'T12:00:00').toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' }) : '';
  return (
    <View style={s.histCard}>
      <View style={s.histLeft}>
        <View style={[s.histChoiceBadge, { backgroundColor: entry.choice === 'A' ? COLORS.ember + '22' : COLORS.mint + '22', borderColor: entry.choice === 'A' ? COLORS.ember : COLORS.mint }]}>
          <Text style={[s.histChoice, { color: entry.choice === 'A' ? COLORS.ember : COLORS.mint }]}>{entry.choice}</Text>
        </View>
      </View>
      <View style={s.histInfo}>
        <Text style={s.histQuestion} numberOfLines={2}>{entry.question}</Text>
        <View style={s.histMeta}>
          <View style={[s.histCategory, { backgroundColor: color + '22', borderColor: color + '60' }]}>
            <Text style={[s.histCategoryText, { color }]}>{entry.category}</Text>
          </View>
          <Text style={s.histDate}>{date}</Text>
        </View>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  center: { flex: 1, backgroundColor: COLORS.background, justifyContent: 'center', alignItems: 'center' },
  scroll: { padding: SPACING.md, paddingBottom: SPACING.xxl },

  screenTitle: { color: COLORS.text, fontSize: 28, fontFamily: 'Fraunces_700Bold', marginBottom: SPACING.lg },

  profileCard: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.lg,
    marginBottom: SPACING.lg,
    borderWidth: 1,
    borderColor: COLORS.border,
    alignItems: 'center',
    gap: SPACING.sm,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: COLORS.ember + '33',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: COLORS.ember,
  },
  avatarText: { color: COLORS.ember, fontSize: 36, fontFamily: 'Fraunces_700Bold' },
  nameRow: { flexDirection: 'row', alignItems: 'center' },
  name: { color: COLORS.text, fontSize: 20, fontFamily: 'Fraunces_700Bold' },
  nameEdit: { fontSize: 14 },
  editNameRow: { flexDirection: 'row', alignItems: 'center', gap: SPACING.sm, width: '100%' },
  nameInput: {
    flex: 1,
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.md,
    paddingVertical: 8,
    color: COLORS.text,
    fontFamily: 'Inter_600SemiBold',
    fontSize: 16,
    borderWidth: 1,
    borderColor: COLORS.ember,
  },
  saveBtn: {
    backgroundColor: COLORS.ember,
    borderRadius: RADIUS.md,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  saveBtnText: { color: COLORS.background, fontFamily: 'Inter_700Bold', fontSize: 16 },
  cancelBtn: {
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.md,
    paddingHorizontal: 10,
    paddingVertical: 8,
  },
  cancelBtnText: { color: COLORS.textMuted, fontFamily: 'Inter_700Bold', fontSize: 16 },
  friendCodeDisplay: { color: COLORS.textDim, fontSize: 13, fontFamily: 'Inter_400Regular' },

  statsRow: { flexDirection: 'row', gap: SPACING.sm, marginBottom: SPACING.lg },
  statCard: {
    flex: 1,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    alignItems: 'center',
    borderWidth: 1,
    gap: 4,
  },
  statEmoji: { fontSize: 24 },
  statValue: { fontSize: 24, fontFamily: 'Fraunces_700Bold' },
  statLabel: { color: COLORS.textDim, fontSize: 11, fontFamily: 'Inter_400Regular' },

  sectionTitle: { color: COLORS.text, fontSize: 18, fontFamily: 'Inter_700Bold', marginBottom: SPACING.md },

  emptyHistory: { padding: SPACING.xl, alignItems: 'center', gap: SPACING.sm },
  emptyEmoji: { fontSize: 40 },
  emptyText: { color: COLORS.text, fontSize: 16, fontFamily: 'Fraunces_700Bold' },
  emptySubtext: { color: COLORS.textMuted, fontSize: 13, fontFamily: 'Inter_400Regular', textAlign: 'center' },

  histCard: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.md,
    padding: SPACING.md,
    marginBottom: SPACING.sm,
    borderWidth: 1,
    borderColor: COLORS.border,
    flexDirection: 'row',
    gap: SPACING.md,
    alignItems: 'center',
  },
  histLeft: { flexShrink: 0 },
  histChoiceBadge: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1.5,
  },
  histChoice: { fontFamily: 'Inter_700Bold', fontSize: 16 },
  histInfo: { flex: 1, gap: 6 },
  histQuestion: { color: COLORS.text, fontSize: 14, fontFamily: 'Inter_400Regular', lineHeight: 18 },
  histMeta: { flexDirection: 'row', alignItems: 'center', gap: SPACING.sm },
  histCategory: {
    borderRadius: RADIUS.full,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderWidth: 1,
  },
  histCategoryText: { fontSize: 10, fontFamily: 'Inter_700Bold', letterSpacing: 0.5 },
  histDate: { color: COLORS.textDim, fontSize: 11, fontFamily: 'Inter_400Regular' },
});
