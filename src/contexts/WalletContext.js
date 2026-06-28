import React, { createContext, useContext, useState, useEffect, useRef, useCallback } from 'react';
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
const SPY_COST = 50;

export function WalletProvider({ children }) {
  const [tokens, setTokens] = useState(0);
  const [spyModeOwned, setSpyModeOwned] = useState(false);
  const [loaded, setLoaded] = useState(false);

  // Refs for synchronous access (state setters are async)
  const tokensRef = useRef(0);
  const spyRef = useRef(false);

  useEffect(() => { tokensRef.current = tokens; }, [tokens]);
  useEffect(() => { spyRef.current = spyModeOwned; }, [spyModeOwned]);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((raw) => {
        if (raw) {
          try {
            const data = JSON.parse(raw);
            const t = data.tokens ?? 0;
            const spy = data.spyModeOwned ?? false;
            tokensRef.current = t;
            spyRef.current = spy;
            setTokens(t);
            setSpyModeOwned(spy);
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
    const next = tokensRef.current + amount;
    tokensRef.current = next;
    setTokens(next);
    persist(next, spyRef.current);
  }, [persist]);

  const spendTokens = useCallback((amount) => {
    const current = tokensRef.current;
    if (current < amount) return false;
    const next = current - amount;
    tokensRef.current = next;
    setTokens(next);
    persist(next, spyRef.current);
    return true;
  }, [persist]);

  const buySpyMode = useCallback(() => {
    if (spyRef.current) return true;
    const current = tokensRef.current;
    if (current < SPY_COST) return false;
    const next = current - SPY_COST;
    tokensRef.current = next;
    spyRef.current = true;
    setTokens(next);
    setSpyModeOwned(true);
    persist(next, true);
    return true;
  }, [persist]);

  const syncTokens = useCallback((amount) => {
    tokensRef.current = amount;
    setTokens(amount);
    persist(amount, spyRef.current);
  }, [persist]);

  if (!loaded) return null;

  return (
    <WalletContext.Provider value={{ tokens, addTokens, spendTokens, spyModeOwned, buySpyMode, syncTokens }}>
      {children}
    </WalletContext.Provider>
  );
}

export const useWallet = () => useContext(WalletContext);
