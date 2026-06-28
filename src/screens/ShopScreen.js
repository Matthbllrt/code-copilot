import React, { useState } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet, ScrollView, Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import * as Haptics from 'expo-haptics';

import { useWallet } from '../contexts/WalletContext';
import { COLORS, SPACING, RADIUS } from '../theme';

const POWERS = [
  {
    id: 'spy',
    emoji: '👁',
    name: 'Mode Espion',
    description: 'Vois les pourcentages globaux AVANT de voter. Aide à te décider… ou à aller à contre-courant.',
    price: 50,
    owned: (wallet) => wallet.spyModeOwned,
    buy: (wallet) => wallet.buySpyMode(),
    color: COLORS.gold,
  },
  {
    id: 'devil',
    emoji: '😈',
    name: 'Avocat du Diable',
    description: 'Épingle une justification provocatrice sous la réponse d\'un ami pour déclencher le débat.',
    price: 30,
    owned: () => false,
    buy: () => false,
    color: COLORS.ember,
    soon: true,
  },
  {
    id: 'bet',
    emoji: '🎰',
    name: 'Bourse aux Paris',
    description: 'Mise des jetons sur la future réponse d\'un ami. Double ou rien !',
    price: 100,
    owned: () => false,
    buy: () => false,
    color: COLORS.mint,
    soon: true,
  },
];

export default function ShopScreen() {
  const wallet = useWallet();
  const [buying, setBuying] = useState(null);

  const handleBuy = async (power) => {
    if (power.soon) {
      Alert.alert('Bientôt disponible', 'Ce pouvoir arrive très prochainement. 😏');
      return;
    }
    if (power.owned(wallet)) {
      Alert.alert('Déjà débloqué', 'Tu possèdes déjà ce pouvoir.');
      return;
    }
    if (wallet.tokens < power.price) {
      Alert.alert(
        'Jetons insuffisants',
        `Il te faut ${power.price} 🪙 pour débloquer ${power.name}.\nVote chaque jour pour en gagner davantage !`
      );
      return;
    }

    Alert.alert(
      `Débloquer ${power.name} ?`,
      `Coût : ${power.price} 🪙\nTon solde : ${wallet.tokens} 🪙`,
      [
        { text: 'Annuler', style: 'cancel' },
        {
          text: 'Acheter',
          onPress: async () => {
            setBuying(power.id);
            try { await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success); } catch {}
            const ok = power.buy(wallet);
            if (ok) {
              Alert.alert('Débloqué ! 🎉', `${power.name} est maintenant actif.`);
            } else {
              Alert.alert('Erreur', 'Achat impossible. Réessaie.');
            }
            setBuying(null);
          },
        },
      ]
    );
  };

  return (
    <SafeAreaView style={s.container} edges={['top']}>
      <ScrollView contentContainerStyle={s.scroll} showsVerticalScrollIndicator={false}>

        <Text style={s.screenTitle}>Boutique</Text>

        {/* Token balance */}
        <View style={s.balanceCard}>
          <Text style={s.balanceLabel}>Ton solde</Text>
          <View style={s.balanceRow}>
            <Text style={s.balanceAmount}>{wallet.tokens}</Text>
            <Text style={s.balanceCoin}>🪙</Text>
          </View>
          <Text style={s.balanceHint}>Vote chaque jour pour gagner des jetons</Text>
          <View style={s.earningGuide}>
            <View style={s.earningItem}>
              <Text style={s.earningEmoji}>🗳</Text>
              <Text style={s.earningText}>Vote du jour</Text>
              <Text style={s.earningAmount}>+10 🪙</Text>
            </View>
            <View style={s.earningItem}>
              <Text style={s.earningEmoji}>🔥</Text>
              <Text style={s.earningText}>Bonus série</Text>
              <Text style={s.earningAmount}>+2 à +20 🪙</Text>
            </View>
          </View>
        </View>

        {/* Powers */}
        <Text style={s.sectionTitle}>Pouvoirs</Text>

        {POWERS.map((power) => {
          const isOwned = power.owned(wallet);
          return (
            <PowerCard
              key={power.id}
              power={power}
              isOwned={isOwned}
              canAfford={wallet.tokens >= power.price}
              onBuy={() => handleBuy(power)}
              loading={buying === power.id}
            />
          );
        })}

        {/* Coming soon section */}
        <View style={s.comingSoonBanner}>
          <Text style={s.comingSoonText}>
            🚧 Cosmétiques, multiplicateurs de jetons et plus arrivent bientôt avec le mode Premium.
          </Text>
        </View>

      </ScrollView>
    </SafeAreaView>
  );
}

function PowerCard({ power, isOwned, canAfford, onBuy, loading }) {
  return (
    <View style={[s.powerCard, { borderColor: power.color + '40' }]}>
      <View style={[s.powerIcon, { backgroundColor: power.color + '1A' }]}>
        <Text style={s.powerEmoji}>{power.emoji}</Text>
      </View>
      <View style={s.powerInfo}>
        <View style={s.powerTitleRow}>
          <Text style={s.powerName}>{power.name}</Text>
          {power.soon ? (
            <View style={s.soonBadge}>
              <Text style={s.soonText}>Bientôt</Text>
            </View>
          ) : null}
          {isOwned ? (
            <View style={[s.ownedBadge, { backgroundColor: power.color + '22', borderColor: power.color }]}>
              <Text style={[s.ownedText, { color: power.color }]}>Débloqué ✓</Text>
            </View>
          ) : null}
        </View>
        <Text style={s.powerDesc}>{power.description}</Text>
        <TouchableOpacity
          style={[
            s.buyBtn,
            { backgroundColor: isOwned ? COLORS.surfaceAlt : canAfford && !power.soon ? power.color : COLORS.surfaceAlt },
            (isOwned || power.soon) && s.buyBtnDisabled,
          ]}
          onPress={onBuy}
          disabled={isOwned || loading}
          activeOpacity={0.8}
        >
          <Text style={[s.buyBtnText, !canAfford && !isOwned && !power.soon && { color: COLORS.textDim }]}>
            {isOwned ? 'Déjà possédé' : power.soon ? 'Bientôt' : `${power.price} 🪙 — Débloquer`}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  scroll: { padding: SPACING.md, paddingBottom: SPACING.xxl },

  screenTitle: { color: COLORS.text, fontSize: 28, fontFamily: 'Fraunces_700Bold', marginBottom: SPACING.lg },

  balanceCard: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.lg,
    marginBottom: SPACING.lg,
    borderWidth: 1,
    borderColor: COLORS.gold + '40',
    alignItems: 'center',
  },
  balanceLabel: { color: COLORS.textMuted, fontSize: 13, fontFamily: 'Inter_400Regular', marginBottom: 4 },
  balanceRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 8 },
  balanceAmount: { color: COLORS.gold, fontSize: 56, fontFamily: 'Fraunces_700Bold' },
  balanceCoin: { fontSize: 32 },
  balanceHint: { color: COLORS.textDim, fontSize: 12, fontFamily: 'Inter_400Regular', marginBottom: SPACING.md },
  earningGuide: { gap: SPACING.sm, width: '100%' },
  earningItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.sm,
    padding: 10,
    gap: SPACING.sm,
  },
  earningEmoji: { fontSize: 20 },
  earningText: { color: COLORS.textMuted, fontSize: 13, fontFamily: 'Inter_400Regular', flex: 1 },
  earningAmount: { color: COLORS.gold, fontSize: 13, fontFamily: 'Inter_700Bold' },

  sectionTitle: { color: COLORS.text, fontSize: 18, fontFamily: 'Inter_700Bold', marginBottom: SPACING.md },

  powerCard: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    marginBottom: SPACING.md,
    borderWidth: 1,
    flexDirection: 'row',
    gap: SPACING.md,
  },
  powerIcon: {
    width: 60,
    height: 60,
    borderRadius: RADIUS.md,
    justifyContent: 'center',
    alignItems: 'center',
    flexShrink: 0,
  },
  powerEmoji: { fontSize: 28 },
  powerInfo: { flex: 1, gap: SPACING.sm },
  powerTitleRow: { flexDirection: 'row', alignItems: 'center', gap: SPACING.sm, flexWrap: 'wrap' },
  powerName: { color: COLORS.text, fontSize: 16, fontFamily: 'Inter_700Bold' },
  soonBadge: {
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.full,
    paddingHorizontal: 8,
    paddingVertical: 2,
  },
  soonText: { color: COLORS.textDim, fontSize: 11, fontFamily: 'Inter_600SemiBold' },
  ownedBadge: {
    borderRadius: RADIUS.full,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderWidth: 1,
  },
  ownedText: { fontSize: 11, fontFamily: 'Inter_600SemiBold' },
  powerDesc: { color: COLORS.textMuted, fontSize: 13, fontFamily: 'Inter_400Regular', lineHeight: 18 },
  buyBtn: {
    borderRadius: RADIUS.md,
    paddingVertical: 10,
    alignItems: 'center',
    marginTop: 4,
  },
  buyBtnDisabled: {},
  buyBtnText: { color: COLORS.background, fontFamily: 'Inter_700Bold', fontSize: 13 },

  comingSoonBanner: {
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.md,
    padding: SPACING.md,
    marginTop: SPACING.sm,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  comingSoonText: { color: COLORS.textMuted, fontSize: 13, fontFamily: 'Inter_400Regular', lineHeight: 18 },
});
