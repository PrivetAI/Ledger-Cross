import SwiftUI

// All icons are custom SwiftUI Shapes / paths. No SF Symbols, no emoji, no system images.

struct PencilIcon: View {
    var color: Color = LCTheme.ink
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Path { p in
                // pencil body
                p.move(to: CGPoint(x: s * 0.20, y: s * 0.80))
                p.addLine(to: CGPoint(x: s * 0.66, y: s * 0.34))
                p.addLine(to: CGPoint(x: s * 0.82, y: s * 0.50))
                p.addLine(to: CGPoint(x: s * 0.36, y: s * 0.96))
                p.closeSubpath()
            }
            .fill(color)
            Path { p in
                // tip
                p.move(to: CGPoint(x: s * 0.20, y: s * 0.80))
                p.addLine(to: CGPoint(x: s * 0.36, y: s * 0.96))
                p.addLine(to: CGPoint(x: s * 0.12, y: s * 1.04))
                p.closeSubpath()
            }
            .fill(color.opacity(0.6))
            Path { p in
                // eraser end
                p.move(to: CGPoint(x: s * 0.66, y: s * 0.34))
                p.addLine(to: CGPoint(x: s * 0.78, y: s * 0.22))
                p.addLine(to: CGPoint(x: s * 0.94, y: s * 0.38))
                p.addLine(to: CGPoint(x: s * 0.82, y: s * 0.50))
                p.closeSubpath()
            }
            .fill(color.opacity(0.4))
        }
    }
}

struct EraserIcon: View {
    var color: Color = LCTheme.ink
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Path { p in
                p.move(to: CGPoint(x: s * 0.30, y: s * 0.66))
                p.addLine(to: CGPoint(x: s * 0.58, y: s * 0.30))
                p.addLine(to: CGPoint(x: s * 0.86, y: s * 0.52))
                p.addLine(to: CGPoint(x: s * 0.66, y: s * 0.78))
                p.addLine(to: CGPoint(x: s * 0.42, y: s * 0.78))
                p.closeSubpath()
            }
            .fill(color)
            Path { p in
                p.move(to: CGPoint(x: s * 0.18, y: s * 0.78))
                p.addLine(to: CGPoint(x: s * 0.86, y: s * 0.78))
            }
            .stroke(color, style: StrokeStyle(lineWidth: s * 0.08, lineCap: .round))
        }
    }
}

struct LightbulbIcon: View {
    var color: Color = LCTheme.amber
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Path { p in
                p.addEllipse(in: CGRect(x: s * 0.26, y: s * 0.12, width: s * 0.48, height: s * 0.48))
            }
            .fill(color)
            Path { p in
                p.move(to: CGPoint(x: s * 0.38, y: s * 0.56))
                p.addLine(to: CGPoint(x: s * 0.62, y: s * 0.56))
                p.addLine(to: CGPoint(x: s * 0.58, y: s * 0.74))
                p.addLine(to: CGPoint(x: s * 0.42, y: s * 0.74))
                p.closeSubpath()
            }
            .fill(color.opacity(0.85))
            // base lines
            ForEach(0..<3) { i in
                Path { p in
                    let y = s * (0.80 + Double(i) * 0.07)
                    p.move(to: CGPoint(x: s * 0.42, y: y))
                    p.addLine(to: CGPoint(x: s * 0.58, y: y))
                }
                .stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
            }
        }
    }
}

struct CheckIcon: View {
    var color: Color = LCTheme.teal
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Path { p in
                p.move(to: CGPoint(x: s * 0.18, y: s * 0.52))
                p.addLine(to: CGPoint(x: s * 0.42, y: s * 0.76))
                p.addLine(to: CGPoint(x: s * 0.84, y: s * 0.24))
            }
            .stroke(color, style: StrokeStyle(lineWidth: s * 0.13, lineCap: .round, lineJoin: .round))
        }
    }
}

struct GearIcon: View {
    var color: Color = LCTheme.ink
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let c = CGPoint(x: s / 2, y: s / 2)
            ZStack {
                ForEach(0..<8) { i in
                    Path { p in
                        let a = Double(i) * .pi / 4
                        let r1 = s * 0.30
                        let r2 = s * 0.46
                        p.move(to: CGPoint(x: c.x + cos(a) * r1, y: c.y + sin(a) * r1))
                        p.addLine(to: CGPoint(x: c.x + cos(a) * r2, y: c.y + sin(a) * r2))
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: s * 0.12, lineCap: .round))
                }
                Path { p in
                    p.addEllipse(in: CGRect(x: s * 0.24, y: s * 0.24, width: s * 0.52, height: s * 0.52))
                }
                .stroke(color, lineWidth: s * 0.10)
                Path { p in
                    p.addEllipse(in: CGRect(x: s * 0.40, y: s * 0.40, width: s * 0.20, height: s * 0.20))
                }
                .fill(color)
            }
        }
    }
}

struct LockIcon: View {
    var color: Color = LCTheme.slateLight
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Path { p in
                p.addRoundedRect(in: CGRect(x: s * 0.26, y: s * 0.46, width: s * 0.48, height: s * 0.40),
                                 cornerSize: CGSize(width: s * 0.06, height: s * 0.06))
            }
            .fill(color)
            Path { p in
                p.addArc(center: CGPoint(x: s * 0.50, y: s * 0.46), radius: s * 0.16,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            }
            .stroke(color, lineWidth: s * 0.08)
        }
    }
}

struct ChevronIcon: View {
    var color: Color = LCTheme.inkSoft
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Path { p in
                p.move(to: CGPoint(x: s * 0.38, y: s * 0.24))
                p.addLine(to: CGPoint(x: s * 0.64, y: s * 0.50))
                p.addLine(to: CGPoint(x: s * 0.38, y: s * 0.76))
            }
            .stroke(color, style: StrokeStyle(lineWidth: s * 0.11, lineCap: .round, lineJoin: .round))
        }
    }
}

struct StarIcon: View {
    var color: Color = LCTheme.amber
    var filled: Bool = true
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let path = starPath(size: s)
            if filled {
                path.fill(color)
            } else {
                path.stroke(color, lineWidth: s * 0.08)
            }
        }
    }
    private func starPath(size s: CGFloat) -> Path {
        var p = Path()
        let c = CGPoint(x: s / 2, y: s / 2)
        let outer = s * 0.44, inner = s * 0.18
        for i in 0..<10 {
            let r = i % 2 == 0 ? outer : inner
            let a = -Double.pi / 2 + Double(i) * .pi / 5
            let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct ClockIcon: View {
    var color: Color = LCTheme.inkSoft
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Path { p in
                    p.addEllipse(in: CGRect(x: s * 0.14, y: s * 0.14, width: s * 0.72, height: s * 0.72))
                }
                .stroke(color, lineWidth: s * 0.09)
                Path { p in
                    p.move(to: CGPoint(x: s * 0.5, y: s * 0.5))
                    p.addLine(to: CGPoint(x: s * 0.5, y: s * 0.28))
                }
                .stroke(color, style: StrokeStyle(lineWidth: s * 0.08, lineCap: .round))
                Path { p in
                    p.move(to: CGPoint(x: s * 0.5, y: s * 0.5))
                    p.addLine(to: CGPoint(x: s * 0.68, y: s * 0.56))
                }
                .stroke(color, style: StrokeStyle(lineWidth: s * 0.08, lineCap: .round))
            }
        }
    }
}

struct UndoIcon: View {
    var color: Color = LCTheme.ink
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Path { p in
                p.addArc(center: CGPoint(x: s * 0.52, y: s * 0.52), radius: s * 0.28,
                         startAngle: .degrees(150), endAngle: .degrees(-90), clockwise: false)
            }
            .stroke(color, style: StrokeStyle(lineWidth: s * 0.10, lineCap: .round))
            Path { p in
                // arrow head
                p.move(to: CGPoint(x: s * 0.18, y: s * 0.30))
                p.addLine(to: CGPoint(x: s * 0.28, y: s * 0.52))
                p.addLine(to: CGPoint(x: s * 0.46, y: s * 0.40))
            }
            .stroke(color, style: StrokeStyle(lineWidth: s * 0.10, lineCap: .round, lineJoin: .round))
        }
    }
}

struct GridMarkIcon: View {
    var color: Color = LCTheme.teal
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Path { p in
                    p.addRoundedRect(in: CGRect(x: s * 0.12, y: s * 0.12, width: s * 0.76, height: s * 0.76),
                                     cornerSize: CGSize(width: s * 0.10, height: s * 0.10))
                }
                .stroke(color, lineWidth: s * 0.08)
                Path { p in
                    p.move(to: CGPoint(x: s * 0.12, y: s * 0.12))
                    p.addLine(to: CGPoint(x: s * 0.42, y: s * 0.42))
                }
                .stroke(color, lineWidth: s * 0.07)
                Path { p in
                    p.move(to: CGPoint(x: s * 0.42, y: s * 0.12)); p.addLine(to: CGPoint(x: s * 0.42, y: s * 0.88))
                    p.move(to: CGPoint(x: s * 0.12, y: s * 0.42)); p.addLine(to: CGPoint(x: s * 0.88, y: s * 0.42))
                }
                .stroke(color.opacity(0.6), lineWidth: s * 0.05)
            }
        }
    }
}

struct CloseIcon: View {
    var color: Color = LCTheme.ink
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Path { p in
                p.move(to: CGPoint(x: s * 0.28, y: s * 0.28))
                p.addLine(to: CGPoint(x: s * 0.72, y: s * 0.72))
                p.move(to: CGPoint(x: s * 0.72, y: s * 0.28))
                p.addLine(to: CGPoint(x: s * 0.28, y: s * 0.72))
            }
            .stroke(color, style: StrokeStyle(lineWidth: s * 0.11, lineCap: .round))
        }
    }
}

struct FlameIcon: View {
    var color: Color = LCTheme.amber
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Path { p in
                p.move(to: CGPoint(x: s * 0.50, y: s * 0.10))
                p.addCurve(to: CGPoint(x: s * 0.78, y: s * 0.60),
                           control1: CGPoint(x: s * 0.66, y: s * 0.28),
                           control2: CGPoint(x: s * 0.80, y: s * 0.42))
                p.addCurve(to: CGPoint(x: s * 0.50, y: s * 0.92),
                           control1: CGPoint(x: s * 0.78, y: s * 0.80),
                           control2: CGPoint(x: s * 0.66, y: s * 0.92))
                p.addCurve(to: CGPoint(x: s * 0.22, y: s * 0.60),
                           control1: CGPoint(x: s * 0.34, y: s * 0.92),
                           control2: CGPoint(x: s * 0.22, y: s * 0.80))
                p.addCurve(to: CGPoint(x: s * 0.42, y: s * 0.34),
                           control1: CGPoint(x: s * 0.22, y: s * 0.46),
                           control2: CGPoint(x: s * 0.34, y: s * 0.46))
                p.closeSubpath()
            }
            .fill(color)
            Path { p in
                p.move(to: CGPoint(x: s * 0.52, y: s * 0.50))
                p.addCurve(to: CGPoint(x: s * 0.62, y: s * 0.70),
                           control1: CGPoint(x: s * 0.60, y: s * 0.56),
                           control2: CGPoint(x: s * 0.62, y: s * 0.62))
                p.addCurve(to: CGPoint(x: s * 0.50, y: s * 0.82),
                           control1: CGPoint(x: s * 0.62, y: s * 0.78),
                           control2: CGPoint(x: s * 0.56, y: s * 0.82))
                p.addCurve(to: CGPoint(x: s * 0.40, y: s * 0.68),
                           control1: CGPoint(x: s * 0.44, y: s * 0.82),
                           control2: CGPoint(x: s * 0.40, y: s * 0.76))
                p.closeSubpath()
            }
            .fill(LCTheme.parchment.opacity(0.7))
        }
    }
}
