import React from 'react';
import { View, Text, ActivityIndicator } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { useFonts, Fraunces_700Bold, Fraunces_700Bold_Italic } from '@expo-google-fonts/fraunces';
import { Inter_400Regular, Inter_600SemiBold, Inter_700Bold } from '@expo-google-fonts/inter';

import ErrorBoundary from './src/components/ErrorBoundary';
import { WalletProvider } from './src/contexts/WalletContext';
import TodayScreen from './src/screens/TodayScreen';
import FriendsScreen from './src/screens/FriendsScreen';
import CirclesScreen from './src/screens/CirclesScreen';
import ShopScreen from './src/screens/ShopScreen';
import ProfileScreen from './src/screens/ProfileScreen';
import { COLORS } from './src/theme';

const Tab = createBottomTabNavigator();

function TabIcon({ emoji, focused }) {
  return (
    <Text style={{ fontSize: 22, opacity: focused ? 1 : 0.5 }}>{emoji}</Text>
  );
}

function WrappedScreen({ Screen, name }) {
  return (
    <ErrorBoundary screenName={name}>
      <Screen />
    </ErrorBoundary>
  );
}

export default function App() {
  const [fontsLoaded, fontError] = useFonts({
    Fraunces_700Bold,
    Fraunces_700Bold_Italic,
    Inter_400Regular,
    Inter_600SemiBold,
    Inter_700Bold,
  });

  if (!fontsLoaded && !fontError) {
    return (
      <View style={{ flex: 1, backgroundColor: COLORS.background, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator color={COLORS.ember} size="large" />
      </View>
    );
  }

  return (
    <ErrorBoundary screenName="App">
      <SafeAreaProvider>
        <WalletProvider>
          <NavigationContainer>
            <StatusBar style="light" />
            <Tab.Navigator
              screenOptions={{
                headerShown: false,
                tabBarStyle: {
                  backgroundColor: COLORS.surface,
                  borderTopColor: COLORS.border,
                  borderTopWidth: 1,
                  height: 64,
                  paddingBottom: 8,
                  paddingTop: 4,
                },
                tabBarActiveTintColor: COLORS.ember,
                tabBarInactiveTintColor: COLORS.textDim,
                tabBarLabelStyle: {
                  fontSize: 11,
                  fontFamily: fontError ? undefined : 'Inter_600SemiBold',
                },
              }}
            >
              <Tab.Screen
                name="Aujourd'hui"
                options={{
                  tabBarIcon: ({ focused }) => <TabIcon emoji="🔥" focused={focused} />,
                }}
              >
                {() => <WrappedScreen Screen={TodayScreen} name="Aujourd'hui" />}
              </Tab.Screen>

              <Tab.Screen
                name="Amis"
                options={{
                  tabBarIcon: ({ focused }) => <TabIcon emoji="🤝" focused={focused} />,
                }}
              >
                {() => <WrappedScreen Screen={FriendsScreen} name="Amis" />}
              </Tab.Screen>

              <Tab.Screen
                name="Cercles"
                options={{
                  tabBarIcon: ({ focused }) => <TabIcon emoji="👥" focused={focused} />,
                }}
              >
                {() => <WrappedScreen Screen={CirclesScreen} name="Cercles" />}
              </Tab.Screen>

              <Tab.Screen
                name="Boutique"
                options={{
                  tabBarIcon: ({ focused }) => <TabIcon emoji="🪙" focused={focused} />,
                }}
              >
                {() => <WrappedScreen Screen={ShopScreen} name="Boutique" />}
              </Tab.Screen>

              <Tab.Screen
                name="Profil"
                options={{
                  tabBarIcon: ({ focused }) => <TabIcon emoji="👤" focused={focused} />,
                }}
              >
                {() => <WrappedScreen Screen={ProfileScreen} name="Profil" />}
              </Tab.Screen>
            </Tab.Navigator>
          </NavigationContainer>
        </WalletProvider>
      </SafeAreaProvider>
    </ErrorBoundary>
  );
}
