# Tap to Repel 🪲

A fast-paced, high-performance Flutter arcade game focused on speed, accuracy, and clearing swarms of pests before the timer runs out.

## 🎮 Gameplay Overview

Unlike traditional reaction games, **Tap to Repel** challenges you to clear entire swarms of pests appearing simultaneously. It's about fast tapping, multitasking, and maintaining focus under pressure.

### Key Features

- **Swarm Mechanics**: Multiple pests spawn at the start of every round. You must clear every single one to progress.
- **Round-Based Progression**: Difficulty scales as you go! Each round adds more pests and tightens the time limit.
- **Dynamic Timer Bar**: A visual countdown that rewards speed. The faster you clear the swarm, the more bonus points you earn from the remaining time.
- **Responsive Feedback**:
  - **Elastic Animations**: Pests pop into existence with satisfying elastic scaling.
  - **Haptic Feedback**: Integrated vibrations for hits and state changes.
  - **Visual Alerts**: Timer bar glows and turns red when time is critically low.
- **Next-Gen UI**: A dark, modern aesthetic with radial gradients and a sleek HUD.

## 🛠 Tech Stack

- **Flutter**: Built with a focus on high-frame-rate rendering and low-latency input.
- **Animations**: Utilizes `AnimatedSwitcher`, `TweenAnimationBuilder`, and `AnimationController` for smooth transitions.
- **State Management**: Lightweight, efficient `StatefulWidget` implementation for maximum performance.

## 🚀 Getting Started

1. **Clone the repo**
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```

## 🧪 Testing

The game includes a comprehensive suite of widget tests verifying:
- Swarm spawning logic.
- Round completion transitions.
- Game Over triggers.

To run the tests:
```bash
flutter test
```

## 📜 License

Distributed under the MIT License.
