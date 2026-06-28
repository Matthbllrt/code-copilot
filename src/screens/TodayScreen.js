import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet, Animated,
  ScrollView, ActivityIndicator, Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  doc, getDoc, setDoc, updateDoc, increment, arrayUnion,
} from 'firebase/firestore';
import * as Haptics from 'expo-haptics';

import { db, getCurrentUser } from '../firebase';
import { useWallet } from '../contexts/WalletContext';
import { COLORS, FONTS, SPACING, RADIUS } from '../theme';

const FALLBACK_DILEMMAS = [
  {
    category: 'Absurde',
    question: 'Maudite pour l\'éternité, tu dois choisir ta malédiction...',
    choiceA: 'Éclats de rire incontrôlables pendant 5 min à chaque enterrement',
    choiceB: 'Crier « C\'EST FAUX ! » chaque fois que quelqu\'un ment',
  },
  {
    category: 'Humour noir',
    question: 'Seul(e) sur une île déserte, tu choisis...',
    choiceA: 'Un téléphone avec batterie infinie mais sans réseau',
    choiceB: 'Un réseau 5G parfait mais sans téléphone',
  },
  {
    category: 'Amour & Psycho',
    question: 'Tu découvres que ton/ta partenaire...',
    choiceA: 'Relit tous tes anciens messages en secret',
    choiceB: 'Note discrètement tous tes défauts dans un carnet',
  },
  {
    category: 'Moral',
    question: 'Dans une catastrophe, tu peux...',
    choiceA: 'Sauver ton meilleur(e) ami(e)',
    choiceB: 'Sauver 10 inconnus',
  },
  {
    category: 'Piquant',
    question: 'Le monde entier peut consulter...',
    choiceA: 'Ton historique Google des 7 derniers jours',
    choiceB: 'Ton dernier brouillon de message jamais envoyé',
  },
  {
    category: 'Absurde',
    question: 'Pour le reste de ta vie, tu dois obligatoirement...',
    choiceA: 'Faire des bruits de voiture chaque fois que tu marches',
    choiceB: 'Narrer chaque action à la troisième personne à voix haute',
  },
  {
    category: 'Piquant',
    question: 'Lors d\'une réunion importante, tu dois...',
    choiceA: 'Rire sans t\'arrêter pendant 3 minutes sans explication',
    choiceB: 'Porter un chapeau ridicule et prétendre que c\'est normal',
  },
];

function getTodayKey() {
  return new Date().toISOString().split('T')[0];
}

function generateFriendCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 6; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

function getDayFallback() {
  const d = new Date().getDay();
  return FALLBACK_DILEMMAS[d % FALLBACK_DILEMMAS.length];
}

export default function TodayScreen() {
  const { addTokens, spyModeOwned, syncTokens } = useWallet();

  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [dilemma, setDilemma] = useState(null);
  const [voted, setVoted] = useState(false);
  const [myChoice, setMyChoice] = useState(null);
  const [friendsVotes, setFriendsVotes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [voting, setVoting] = useState(false);
  const [tokensEarned, setTokensEarned] = useState(0);

  const revealAnim = useRef(new Animated.Value(0)).current;
  const tokenAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        const u = await getCurrentUser();
        if (!mounted) return;
        setUser(u);
        await init(u.uid, mounted);
      } catch {
        if (mounted) setLoading(false);
      }
    })();
    return () => { mounted = false; };
  }, []);

  const init = async (uid, mounted = true) => {
    try {
      const today = getTodayKey();

      const dilemmaRef = doc(db, 'dilemmas', today);
      const dilemmaSnap = await getDoc(dilemmaRef).catch(() => null);
      const dilemmaData = dilemmaSnap?.exists()
        ? { id: today, votesA: 0, votesB: 0, ...dilemmaSnap.data() }
        : { id: today, votesA: 0, votesB: 0, source: 'fallback', ...getDayFallback() };

      if (!mounted) return;
      setDilemma(dilemmaData);

      const userRef = doc(db, 'users', uid);
      const userSnap = await getDoc(userRef).catch(() => null);

      if (userSnap?.exists()) {
        const p = userSnap.data();
        if (!mounted) return;
        setProfile(p);
        syncTokens(p.tokens ?? 0);

        if (p.lastVoteDate === today) {
          setVoted(true);
          setMyChoice(p.lastVoteChoice);
          revealAnim.setValue(1);
          await loadFriendsVotes(p.friends ?? [], today);
        }
      } else {
        const code = generateFriendCode();
        const p = {
          displayName: 'Joueur',
          friendCode: code,
          friends: [],
          circles: [],
          streak: 0,
          lastVoteDate: null,
          lastVoteChoice: null,
          lastVoteCategory: null,
          lastVoteQuestion: null,
          tokens: 0,
          voteHistory: [],
          createdAt: new Date(),
        };
        await setDoc(userRef, p).catch(() => {});
        await setDoc(doc(db, 'friendCodes', code), { uid }).catch(() => {});
        if (!mounted) return;
        setProfile(p);
      }
    } catch (e) {
      console.warn('TodayScreen init error:', e);
    } finally {
      if (mounted) setLoading(false);
    }
  };

  const loadFriendsVotes = async (friendUids, today) => {
    if (!friendUids.length) return;
    try {
      const results = await Promise.all(
        friendUids.slice(0, 12).map(async (uid) => {
          const snap = await getDoc(doc(db, 'users', uid)).catch(() => null);
          if (!snap?.exists()) return null;
          const d = snap.data();
          return {
            uid,
            name: d.displayName || 'Ami',
            votedToday: d.lastVoteDate === today,
            choice: d.lastVoteChoice,
          };
        })
      );
      setFriendsVotes(results.filter(Boolean));
    } catch {}
  };

  const handleVote = async (choice) => {
    if (voted || voting || !user || !dilemma) return;
    setVoting(true);
    try { await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium); } catch {}

    const today = getTodayKey();

    try {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yk = yesterday.toISOString().split('T')[0];
      const newStreak = profile?.lastVoteDate === yk ? (profile.streak || 0) + 1 : 1;
      const earned = 10 + Math.min(newStreak * 2, 20);

      const voteField = choice === 'A' ? 'votesA' : 'votesB';
      const dilemmaRef = doc(db, 'dilemmas', today);

      try {
        await updateDoc(dilemmaRef, { [voteField]: increment(1) });
      } catch {
        await setDoc(dilemmaRef, {
          ...dilemma,
          votesA: choice === 'A' ? (dilemma.votesA || 0) + 1 : (dilemma.votesA || 0),
          votesB: choice === 'B' ? (dilemma.votesB || 0) + 1 : (dilemma.votesB || 0),
        }).catch(() => {});
      }

      const historyEntry = {
        date: today,
        choice,
        category: dilemma.category,
        question: dilemma.question,
      };

      await updateDoc(doc(db, 'users', user.uid), {
        lastVoteDate: today,
        lastVoteChoice: choice,
        lastVoteCategory: dilemma.category,
        lastVoteQuestion: dilemma.question,
        streak: newStreak,
        tokens: increment(earned),
        voteHistory: arrayUnion(historyEntry),
      }).catch(() => {});

      setDilemma((prev) => ({
        ...prev,
        [voteField]: (prev[voteField] || 0) + 1,
      }));
      setMyChoice(choice);
      setVoted(true);
      setTokensEarned(earned);
      setProfile((prev) => ({
        ...prev,
        streak: newStreak,
        lastVoteDate: today,
        lastVoteChoice: choice,
        tokens: (prev?.tokens || 0) + earned,
      }));
      addTokens(earned);

      Animated.timing(revealAnim, { toValue: 1, duration: 700, useNativeDriver: true }).start();

      Animated.sequence([
        Animated.timing(tokenAnim, { toValue: 1, duration: 300, useNativeDriver: true }),
        Animated.delay(1800),
        Animated.timing(tokenAnim, { toValue: 0, duration: 400, useNativeDriver: true }),
      ]).start();

      await loadFriendsVotes(profile?.friends ?? [], today);
    } catch (e) {
      console.warn('Vote error:', e);
      Alert.alert('Erreur', 'Impossible de voter. Vérifie ta connexion.');
    } finally {
      setVoting(false);
    }
  };

  if (loading) {
    return (
      <View style={s.center}>
        <ActivityIndicator color={COLORS.ember} size="large" />
        <Text style={s.loadingText}>Chargement du dilemme...</Text>
      </View>
    );
  }

  const totalVotes = (dilemma?.votesA || 0) + (dilemma?.votesB || 0);
  const pctA = totalVotes > 0 ? Math.round(((dilemma?.votesA || 0) / totalVotes) * 100) : 50;
  const pctB = 100 - pctA;

  return (
    <SafeAreaView style={s.container} edges={['top']}>
      <ScrollView contentContainerStyle={s.scroll} showsVerticalScrollIndicator={false}>

        {/* Header */}
        <View style={s.header}>
          <View>
            <Text style={s.appName}>Cercle</Text>
            <Text style={s.dateText}>
              {new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' })}
            </Text>
          </View>
          <View style={s.streakBadge}>
            <Text style={s.streakText}>🔥 {profile?.streak || 0}</Text>
          </View>
        </View>

        {/* Category badge */}
        {dilemma?.category ? (
          <View style={s.categoryBadge}>
            <Text style={s.categoryText}>{dilemma.category.toUpperCase()}</Text>
          </View>
        ) : null}

        {/* Question */}
        <Text style={s.question}>{dilemma?.question || 'Chargement…'}</Text>

        {/* Spy mode preview before voting */}
        {!voted && spyModeOwned && totalVotes > 0 ? (
          <View style={s.spyPreview}>
            <Text style={s.spyLabel}>👁 Mode Espion</Text>
            <Text style={s.spyText}>A {pctA}%  ·  B {pctB}%</Text>
          </View>
        ) : null}

        {/* Vote buttons or Results */}
        {!voted ? (
          <View style={s.choices}>
            <TouchableOpacity
              style={[s.choiceBtn, s.choiceA]}
              onPress={() => handleVote('A')}
              disabled={voting}
              activeOpacity={0.75}
            >
              <View style={s.choiceLetterWrap}>
                <Text style={s.choiceLetter}>A</Text>
              </View>
              <Text style={s.choiceText}>{dilemma?.choiceA}</Text>
            </TouchableOpacity>

            <Text style={s.orText}>ou</Text>

            <TouchableOpacity
              style={[s.choiceBtn, s.choiceB]}
              onPress={() => handleVote('B')}
              disabled={voting}
              activeOpacity={0.75}
            >
              <View style={[s.choiceLetterWrap, s.choiceLetterB]}>
                <Text style={s.choiceLetter}>B</Text>
              </View>
              <Text style={s.choiceText}>{dilemma?.choiceB}</Text>
            </TouchableOpacity>

            {voting ? (
              <ActivityIndicator color={COLORS.ember} style={{ marginTop: 12 }} />
            ) : null}
          </View>
        ) : (
          <Animated.View style={{ opacity: revealAnim }}>
            {/* My vote banner */}
            <View style={s.myVote}>
              <Text style={s.myVoteLabel}>Tu as voté :</Text>
              <Text style={s.myVoteValue}>
                {myChoice} — {myChoice === 'A' ? dilemma?.choiceA : dilemma?.choiceB}
              </Text>
            </View>

            {/* Percentages */}
            <View style={s.percentages}>
              <BarRow
                letter="A"
                label={dilemma?.choiceA}
                pct={pctA}
                color={COLORS.ember}
                mine={myChoice === 'A'}
              />
              <BarRow
                letter="B"
                label={dilemma?.choiceB}
                pct={pctB}
                color={COLORS.mint}
                mine={myChoice === 'B'}
              />
            </View>
            <Text style={s.totalText}>{totalVotes} vote{totalVotes > 1 ? 's' : ''} au total</Text>

            {/* Friends votes */}
            {friendsVotes.length > 0 ? (
              <View style={s.friendsSection}>
                <Text style={s.friendsSectionTitle}>Tes proches ont répondu :</Text>
                <View style={s.friendsGrid}>
                  {friendsVotes.map((f) => (
                    <FriendVoteCard key={f.uid} friend={f} myChoice={myChoice} />
                  ))}
                </View>
              </View>
            ) : (
              <View style={s.noFriends}>
                <Text style={s.noFriendsEmoji}>👻</Text>
                <Text style={s.noFriendsTitle}>Tu es seul ici</Text>
                <Text style={s.noFriendsText}>Invite tes proches pour voir leurs réponses !</Text>
              </View>
            )}
          </Animated.View>
        )}
      </ScrollView>

      {/* Token notification overlay */}
      <Animated.View style={[s.tokenNotif, { opacity: tokenAnim }]} pointerEvents="none">
        <Text style={s.tokenNotifText}>+{tokensEarned} 🪙</Text>
      </Animated.View>
    </SafeAreaView>
  );
}

function BarRow({ letter, label, pct, color, mine }) {
  return (
    <View style={s.barRow}>
      <View style={s.barHeader}>
        <View style={[s.barLetter, { backgroundColor: color + '22', borderColor: color }]}>
          <Text style={[s.barLetterText, { color }]}>{letter}</Text>
        </View>
        <Text style={[s.barPct, mine && { color, fontFamily: 'Inter_700Bold' }]}>{pct}%</Text>
        {mine ? <Text style={s.mineTag}>← toi</Text> : null}
      </View>
      <View style={s.barTrack}>
        <View style={[s.barFill, { width: `${pct}%`, backgroundColor: color }]} />
      </View>
      <Text style={s.barLabel} numberOfLines={1}>{label}</Text>
    </View>
  );
}

function FriendVoteCard({ friend, myChoice }) {
  const agree = friend.votedToday && friend.choice === myChoice;
  const color = agree ? COLORS.ember : COLORS.mint;
  return (
    <View style={s.friendCard}>
      <View style={[s.friendAvatar, { borderColor: friend.votedToday ? color : COLORS.border }]}>
        <Text style={s.friendAvatarText}>{friend.name.charAt(0).toUpperCase()}</Text>
      </View>
      <Text style={s.friendName} numberOfLines={1}>{friend.name}</Text>
      {friend.votedToday ? (
        <Text style={[s.friendChoice, { color }]}>{friend.choice}</Text>
      ) : (
        <Text style={s.friendPending}>⏳</Text>
      )}
    </View>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  center: { flex: 1, backgroundColor: COLORS.background, justifyContent: 'center', alignItems: 'center', gap: 12 },
  loadingText: { color: COLORS.textMuted, fontSize: 14 },
  scroll: { padding: SPACING.md, paddingBottom: SPACING.xxl },

  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: SPACING.lg },
  appName: { color: COLORS.ember, fontSize: 22, fontFamily: 'Fraunces_700Bold', letterSpacing: 0.5 },
  dateText: { color: COLORS.textMuted, fontSize: 13, marginTop: 2 },
  streakBadge: {
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.full,
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  streakText: { color: COLORS.white, fontSize: 14, fontFamily: 'Inter_600SemiBold' },

  categoryBadge: {
    alignSelf: 'flex-start',
    backgroundColor: COLORS.ember + '1A',
    borderRadius: RADIUS.full,
    paddingHorizontal: 12,
    paddingVertical: 4,
    marginBottom: SPACING.md,
    borderWidth: 1,
    borderColor: COLORS.ember + '40',
  },
  categoryText: { color: COLORS.ember, fontSize: 10, fontFamily: 'Inter_700Bold', letterSpacing: 1.5 },

  question: {
    fontSize: 26,
    color: COLORS.text,
    fontFamily: 'Fraunces_700Bold',
    lineHeight: 34,
    marginBottom: SPACING.xl,
  },

  spyPreview: {
    backgroundColor: COLORS.gold + '1A',
    borderRadius: RADIUS.md,
    padding: SPACING.sm,
    marginBottom: SPACING.md,
    borderWidth: 1,
    borderColor: COLORS.gold + '40',
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.sm,
  },
  spyLabel: { color: COLORS.gold, fontSize: 13, fontFamily: 'Inter_600SemiBold' },
  spyText: { color: COLORS.gold, fontSize: 13 },

  choices: { gap: SPACING.md },
  choiceBtn: {
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    borderWidth: 1.5,
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.md,
  },
  choiceA: { borderColor: COLORS.ember, backgroundColor: COLORS.ember + '0D' },
  choiceB: { borderColor: COLORS.mint, backgroundColor: COLORS.mint + '0D' },
  choiceLetterWrap: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: COLORS.ember,
    justifyContent: 'center',
    alignItems: 'center',
  },
  choiceLetterB: { backgroundColor: COLORS.mint },
  choiceLetter: { color: COLORS.background, fontFamily: 'Inter_700Bold', fontSize: 16 },
  choiceText: { color: COLORS.text, fontSize: 16, flex: 1, lineHeight: 22, fontFamily: 'Inter_400Regular' },
  orText: { textAlign: 'center', color: COLORS.textDim, fontSize: 14, fontFamily: 'Inter_400Regular' },

  myVote: {
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.md,
    padding: SPACING.md,
    marginBottom: SPACING.lg,
  },
  myVoteLabel: { color: COLORS.textMuted, fontSize: 12, marginBottom: 4, fontFamily: 'Inter_400Regular' },
  myVoteValue: { color: COLORS.ember, fontSize: 16, fontFamily: 'Inter_600SemiBold' },

  percentages: { gap: SPACING.md, marginBottom: SPACING.sm },
  barRow: { gap: 6 },
  barHeader: { flexDirection: 'row', alignItems: 'center', gap: SPACING.sm },
  barLetter: {
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
  },
  barLetterText: { fontFamily: 'Inter_700Bold', fontSize: 13 },
  barPct: { color: COLORS.text, fontSize: 18, fontFamily: 'Inter_600SemiBold' },
  mineTag: { color: COLORS.textMuted, fontSize: 12, fontFamily: 'Inter_400Regular' },
  barTrack: { height: 8, backgroundColor: COLORS.border, borderRadius: 4, overflow: 'hidden' },
  barFill: { height: '100%', borderRadius: 4 },
  barLabel: { color: COLORS.textMuted, fontSize: 12, fontFamily: 'Inter_400Regular' },

  totalText: { color: COLORS.textDim, fontSize: 12, textAlign: 'center', marginBottom: SPACING.xl, fontFamily: 'Inter_400Regular' },

  friendsSection: { marginTop: SPACING.sm },
  friendsSectionTitle: { color: COLORS.textMuted, fontSize: 14, marginBottom: SPACING.md, fontFamily: 'Inter_600SemiBold' },
  friendsGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: SPACING.md },
  friendCard: { alignItems: 'center', width: 60 },
  friendAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: COLORS.surfaceAlt,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 4,
    borderWidth: 2,
  },
  friendAvatarText: { color: COLORS.white, fontFamily: 'Inter_700Bold', fontSize: 18 },
  friendName: { color: COLORS.textMuted, fontSize: 10, textAlign: 'center', fontFamily: 'Inter_400Regular' },
  friendChoice: { fontFamily: 'Inter_700Bold', fontSize: 14 },
  friendPending: { fontSize: 14 },

  noFriends: { padding: SPACING.xl, alignItems: 'center', gap: SPACING.sm },
  noFriendsEmoji: { fontSize: 48 },
  noFriendsTitle: { color: COLORS.text, fontSize: 18, fontFamily: 'Fraunces_700Bold' },
  noFriendsText: { color: COLORS.textMuted, fontSize: 14, textAlign: 'center', fontFamily: 'Inter_400Regular' },

  tokenNotif: {
    position: 'absolute',
    top: 80,
    alignSelf: 'center',
    backgroundColor: COLORS.gold,
    borderRadius: RADIUS.full,
    paddingHorizontal: 20,
    paddingVertical: 10,
    shadowColor: COLORS.gold,
    shadowOpacity: 0.6,
    shadowRadius: 12,
    elevation: 8,
  },
  tokenNotifText: { color: '#000', fontFamily: 'Inter_700Bold', fontSize: 16 },
});
