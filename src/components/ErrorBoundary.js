import React from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';

export default class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, info: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, info) {
    this.setState({ info });
  }

  render() {
    if (this.state.hasError) {
      return (
        <View style={styles.container}>
          <Text style={styles.emoji}>🔧</Text>
          <Text style={styles.title}>Quelque chose s'est cassé</Text>
          <Text style={styles.subtitle}>
            {this.props.screenName ? `Écran : ${this.props.screenName}` : 'Une erreur inattendue est survenue'}
          </Text>
          <ScrollView style={styles.errorBox}>
            <Text style={styles.errorText}>{this.state.error?.toString()}</Text>
            {this.state.info?.componentStack ? (
              <Text style={styles.stackText}>{this.state.info.componentStack}</Text>
            ) : null}
          </ScrollView>
          <TouchableOpacity
            style={styles.retryBtn}
            onPress={() => this.setState({ hasError: false, error: null, info: null })}
          >
            <Text style={styles.retryText}>Réessayer</Text>
          </TouchableOpacity>
        </View>
      );
    }
    return this.props.children;
  }
}

const styles = {
  container: {
    flex: 1,
    backgroundColor: '#0D0A1A',
    padding: 24,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emoji: { fontSize: 48, marginBottom: 16 },
  title: { color: '#FF6B35', fontSize: 20, fontWeight: 'bold', marginBottom: 8, textAlign: 'center' },
  subtitle: { color: '#9B8FC7', fontSize: 14, marginBottom: 16, textAlign: 'center' },
  errorBox: {
    backgroundColor: '#1A1428',
    borderRadius: 12,
    padding: 12,
    maxHeight: 200,
    width: '100%',
    marginBottom: 20,
  },
  errorText: { color: '#FF4757', fontSize: 12, fontFamily: 'monospace' },
  stackText: { color: '#5C5280', fontSize: 10, marginTop: 8 },
  retryBtn: {
    backgroundColor: '#FF6B35',
    borderRadius: 24,
    paddingHorizontal: 32,
    paddingVertical: 12,
  },
  retryText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
};
