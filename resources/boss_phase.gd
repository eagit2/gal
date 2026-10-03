class_name BossPhase
extends Resource
## One phase of a boss (an EliteDef with phases): starts once the boss's hp falls to `at` of its
## max, and runs these traits on top of the boss's own until the next phase.

@export_range(0.0, 1.0) var at: float = 1.0
@export var traits: Array[EliteTrait] = []
