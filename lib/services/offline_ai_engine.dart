class OfflineAiEngine {
  static String generateResponse(String prompt) {
    final lower = prompt.toLowerCase().trim();

    if (lower.contains('hi') ||
        lower.contains('hello') ||
        lower.contains('hey') ||
        lower.contains('greetings')) {
      return "⚡ [Gemini Nano 4 Edge AI]: Hello! I am operating fully offline on your device. I'm ready to assist you with emergency protocols, evacuation routes, and first aid even without internet signal.";
    } else if (lower.contains('water') ||
        lower.contains('purif') ||
        lower.contains('drink')) {
      return "⚡ [Gemini Nano 4 Edge AI - Water Safety Protocol]: \n1. Boil water at a rolling boil for at least 1 minute.\n2. If boiling is unavailable, add 8 drops of unscented household bleach per gallon of water, stir well, and let stand for 30 minutes before consuming.";
    } else if (lower.contains('high') ||
        lower.contains('ground') ||
        lower.contains('evacuate') ||
        lower.contains('safe')) {
      return "⚡ [Gemini Nano 4 Edge AI - Evacuation Guide]: \n• Relocate immediately to higher ground away from rivers, streams, and low-lying zones.\n• Do not walk through moving flood water—6 inches of swift water can knock an adult down.\n• Keep emergency contacts and ID papers in a sealed waterproof container.";
    } else if (lower.contains('electric') ||
        lower.contains('power') ||
        lower.contains('shock') ||
        lower.contains('wire')) {
      return "⚡ [Gemini Nano 4 Edge AI - Electrical Safety]: \n• Turn off your home's main power circuit breaker if water begins entering the structure.\n• Never touch electrical appliances while standing in water or if you are wet.\n• Stay at least 30 feet away from downed power lines.";
    } else if (lower.contains('sos') ||
        lower.contains('help') ||
        lower.contains('emergency')) {
      return "⚡ [Gemini Nano 4 Edge AI - Emergency SOS]: \n• If trapped, move to the highest floor or roof immediately.\n• Signal for help using a bright cloth, flashlight, or whistle.\n• Universal Emergency Number: 112 / 911.";
    } else {
      return "⚡ [Gemini Nano 4 Edge AI]: I analyzed your query (\"$prompt\") locally on-device. While offline, remember key disaster rules: Move to higher ground, avoid flood currents, and keep your emergency kit close. (Connect to internet for 100% Cloud Gemini 3.8 Flash advanced reasoning).";
    }
  }
}
