import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const WalletContext = createContext({
  tokens: 0,
  addTokens: () => {},
  spendTokens: () => false,
  spyModeOwned: false,
  buySpyMode: () => false,
  syncTokens: () => {},
});

const STORAGE_KEY = 'cercle_wallet';

export function WalletProvider({ children }) {
  const [tokens, setTokens] = useState(0);
  const [spyModeOwned, setSpyModeOwned] = useState(false);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((raw) => {
        if (raw) {
          try {
            const data = JSON.parse(raw);
            setTokens(data.tokens ?? 0);
            setSpyModeOwned(data.spyModeOwned ?? false);
          } catch {}
        }
      })
      .catch(() => {})
      .finally(() => setLoaded(true));
  }, []);

  const persist = useCallback((t, spy) => {
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify({ tokens: t, spyModeOwned: spy })).catch(() => {});
  }, []);

  const addTokens = useCallback((amount) => {
    setTokens((prev) => {
      const next = prev + amount;
      setSpyModeOwned((spy) => { persist(next, spy); return spy; });
      return next;
    });
  }, [persist]);

  const spendTokens = useCallback((amount) => {
    let success = false;
    setTokens((prev) => {
      if (prev < amount) return prev;
      success = true;
      const next = prev - amount;
      setSpyModeOwned((spy) => { persist(next, spy); return spy; });
      return next;
    });
    return success;
  }, [persist]);

  const buySpyMode = useCallback(() => {
    const SPY_COST = 50;
    if (spyModeOwned) return true;
    let success = false;
    setTokens((prev) => {
      if (prev < SPY_COST) return prev;
      success = true;
      const next = prev - SPY_COST;
      setSpyModeOwned(true);
      persist(next, true);
      return next;
    });
    return success;
  }, [spyModeOwned, persist]);

  const syncTokens = useCallback((amount) => {
    setTokens(amount);
    setSpyModeOwned((spy) => { persist(amount, spy); return spy; });
  }, [persist]);

  if (!loaded) return null;

  return (
    <WalletContext.Provider value={{ tokens, addTokens, spendTokens, spyModeOwned, buySpyMode, syncTokens }}>
      {children}
    </WalletContext.Provider>
  );
}

export const useWallet = () => useContext(WalletContext);
