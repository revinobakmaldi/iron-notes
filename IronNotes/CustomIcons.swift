import SwiftUI

struct CustomIcons {
    static func icon(_ name: String, size: CGFloat = 24, color: Color = .blue, background: Color? = nil) -> some View {
        ZStack {
            if let bg = background {
                Circle()
                    .fill(bg)
                    .frame(width: size * 1.2, height: size * 1.2)
            }

            Image(systemName: name)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(color)
        }
    }

    static func animatedIcon(_ name: String, size: CGFloat = 24, color: Color = .blue) -> some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .medium))
            .foregroundColor(color)
            .symbolEffect(.pulse, options: .repeating, isActive: true)
    }
}

struct TimeBasedGreeting: View {
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "Good morning! ☀️"
        case 12..<17:
            return "Good afternoon! 🌤️"
        case 17..<21:
            return "Good evening! 🌅"
        default:
            return "Good night! 🌙"
        }
    }

    @State private var animateGreeting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .scaleEffect(animateGreeting ? 1 : 0.95)
                .opacity(animateGreeting ? 1 : 0)

            Text("Ready to crush it today?")
                .font(.subheadline)
                .foregroundColor(.gray)
                .offset(y: animateGreeting ? 0 : 10)
                .opacity(animateGreeting ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animateGreeting = true
            }
        }
    }
}
