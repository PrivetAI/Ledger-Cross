import SwiftUI

// Clean paper / ledger theme — forced light appearance.
enum KCSTheme {
    static let parchment = Color(red: 0.965, green: 0.945, blue: 0.898)   // cream background
    static let paper      = Color(red: 0.992, green: 0.984, blue: 0.965)  // entry cell white
    static let card       = Color(red: 0.984, green: 0.969, blue: 0.933)
    static let ink        = Color(red: 0.180, green: 0.196, blue: 0.219)  // charcoal grid
    static let inkSoft    = Color(red: 0.180, green: 0.196, blue: 0.219).opacity(0.55)
    static let slate      = Color(red: 0.235, green: 0.282, blue: 0.318)  // clue cells
    static let slateLight = Color(red: 0.380, green: 0.435, blue: 0.470)
    static let teal       = Color(red: 0.012, green: 0.514, blue: 0.510)  // selection accent
    static let tealSoft   = Color(red: 0.012, green: 0.514, blue: 0.510).opacity(0.16)
    static let red        = Color(red: 0.788, green: 0.235, blue: 0.184)  // conflicts
    static let redSoft    = Color(red: 0.788, green: 0.235, blue: 0.184).opacity(0.16)
    static let amber      = Color(red: 0.847, green: 0.561, blue: 0.149)  // hint / star
    static let line       = Color(red: 0.180, green: 0.196, blue: 0.219).opacity(0.30)
    static let highlight  = Color(red: 0.012, green: 0.514, blue: 0.510).opacity(0.08) // run highlight
}

// Light haptic + sound helper respecting settings.
import UIKit
import AudioToolbox

enum KCSFeedback {
    static func tap() {
        let s = KakuroStore.shared.settings
        if s.hapticsOn {
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
        }
    }

    static func success() {
        let s = KakuroStore.shared.settings
        if s.hapticsOn {
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        }
        if s.soundOn {
            AudioServicesPlaySystemSound(1057)
        }
    }

    static func error() {
        let s = KakuroStore.shared.settings
        if s.hapticsOn {
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.warning)
        }
    }

    static func soft() {
        let s = KakuroStore.shared.settings
        if s.soundOn {
            AudioServicesPlaySystemSound(1104)
        }
    }
}
