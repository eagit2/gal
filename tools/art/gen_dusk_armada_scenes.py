#!/usr/bin/env python3
"""Writes the Dusk Armada StyledVisual scenes (.tscn) for ships, enemies, shots and the pickup.

Each scene: a StyledVisual root with a `dusk_armada` child holding the sprite, a hidden
`Silhouette` of polygons (vector styles build their neon wireframe from it), and for ships a
DamageFx node with hit sparks and damage smoke. Run after gen_dusk_armada.py when the sprite
list or layout changes; hand edits to these scenes are overwritten.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets" / "art" / "dusk_armada"
RES = "res://assets/art/dusk_armada"

CYAN, ORANGE, YELLOW, PINK, RED = (
    "0.176, 0.886, 0.902, 1", "1, 0.608, 0.239, 1", "0.976, 0.973, 0.443, 1",
    "1, 0.247, 0.847, 1", "1, 0.302, 0.427, 1")

# name: (png, anim frames, fps, damage frames?, neon color, silhouette polygons)
SHIPS = {
    "player": ("player", 2, 12, False, PINK, {
        "Hull": "0, -24, 7, -6, 20, 10, 20, 18, 6, 12, 0, 18, -6, 12, -20, 18, -20, 10, -7, -6",
        "Cockpit": "0, -12, 4, 0, 0, 4, -4, 0"}),
    "enemies/bee": ("enemies/bee", 2, 3, False, CYAN, {
        "WingL": "-6, -4, -16, -12, -16, 2, -6, 4", "WingR": "6, -4, 16, -12, 16, 2, 6, 4",
        "Body": "0, -12, 7, -4, 6, 8, 0, 13, -6, 8, -7, -4"}),
    "enemies/moth": ("enemies/moth", 2, 3, False, ORANGE, {
        "WingL": "-5, -6, -18, -14, -20, 4, -8, 8", "WingR": "5, -6, 18, -14, 20, 4, 8, 8",
        "Body": "0, -12, 6, -2, 4, 12, -4, 12, -6, -2"}),
    "enemies/warden": ("enemies/warden", 2, 3, True, YELLOW, {
        "WingL": "-9, -6, -22, -2, -20, 10, -9, 8", "WingR": "9, -6, 22, -2, 20, 10, 9, 8",
        "Body": "-8, -14, 8, -14, 12, -4, 10, 10, 0, 16, -10, 10, -12, -4",
        "Crown": "-8, 14, -4, 20, 0, 14, 4, 20, 8, 14"}),
    "enemies/fusewing": ("enemies/fusewing", 2, 6, False, ORANGE, {
        "Body": "-6, -9, 6, -9, 13, -3, 13, 4, 6, 9, -6, 9, -13, 4, -13, -3",
        "Core": "0, -4, 4, 0, 0, 4, -4, 0"}),
    "enemies/lancer": ("enemies/lancer", 2, 6, True, CYAN, {
        "Body": "0, -14, 4, -8, 13, -3, 13, 2, 4, -1, 2, 14, 0, 18, -2, 14, -4, -1, -13, 2, -13, -3, -4, -8"}),
    "enemies/spinner": ("enemies/spinner", 2, 6, True, PINK, {
        "Hull": "0, -14, 10, -10, 14, 0, 10, 10, 0, 14, -10, 10, -14, 0, -10, -10",
        "Core": "0, -5, 5, 0, 0, 5, -5, 0"}),
    "enemies/shieldbearer": ("enemies/shieldbearer", 2, 3, True, YELLOW, {
        "Body": "-10, -10, 10, -10, 17, -2, 10, 6, -10, 6, -17, -2",
        "Shield": "-15, 7, 15, 7, 15, 11, -15, 11"}),
}
# name: (png, frames, fps, neon color, glow tint, glow scale, sprite y offset, silhouette)
SHOTS = {
    "projectiles/player_bullet": ("projectiles/player_bullet", 2, 20, CYAN, "0.5, 0.95, 1, 0.7",
                                  "0.45, 1.1", 8, {"Bolt": "-2, -9, 2, -9, 2, 9, -2, 9"}),
    "projectiles/enemy_bullet": ("projectiles/enemy_bullet", 2, 12, RED, "1, 0.3, 0.43, 0.8",
                                 "0.9, 0.9", 0, {"Orb": "0, -6, 5, 0, 0, 6, -5, 0"}),
    "pickup": ("pickup", 2, 6, YELLOW, "1, 0.88, 0.54, 0.35", "1.2, 1.2", 0,
               {"Capsule": "0, -9, 7, -6, 9, 0, 7, 6, 0, 9, -7, 6, -9, 0, -7, -6"}),
}

PARTICLES = """
[node name="Sparks" type="CPUParticles2D" parent="dusk_armada/DamageFx"]
emitting = false
amount = 10
lifetime = 0.3
one_shot = true
explosiveness = 1.0
local_coords = false
spread = 180.0
gravity = Vector2(0, 0)
initial_velocity_min = 90.0
initial_velocity_max = 190.0
damping_min = 300.0
damping_max = 400.0
scale_amount_min = 2.0
scale_amount_max = 3.0
color_ramp = SubResource("spark_ramp")

[node name="Smoke" type="CPUParticles2D" parent="dusk_armada/DamageFx"]
emitting = false
amount = 8
lifetime = 0.7
local_coords = false
direction = Vector2(0, -1)
spread = 25.0
gravity = Vector2(0, -30)
initial_velocity_min = 10.0
initial_velocity_max = 25.0
scale_amount_min = 3.0
scale_amount_max = 5.0
color_ramp = SubResource("smoke_ramp")
"""


def silhouette(polys: dict) -> list:
    out = ['[node name="Silhouette" type="Node2D" parent="dusk_armada"]', "visible = false", ""]
    for n, pts in polys.items():
        out += [f'[node name="{n}" type="Polygon2D" parent="dusk_armada/Silhouette"]',
                f"polygon = PackedVector2Array({pts})", ""]
    return out


def ship(name: str, png: str, frames: int, fps: int, damage: bool, neon: str, polys: dict) -> None:
    hframes = frames * 2 if damage else frames
    extra = ""
    if name == "player":
        extra = "\n".join([
            "", '[node name="MuzzleFlash" type="Sprite2D" parent="dusk_armada"]',
            "position = Vector2(0, -30)", "scale = Vector2(2, 2)", 'texture = ExtResource("7")',
            "hframes = 2", 'script = ExtResource("6")', ""])
    lines = [
        "[gd_scene load_steps=12 format=3]", "",
        '[ext_resource type="Script" path="res://scenes/components/styled_visual.gd" id="1"]',
        f'[ext_resource type="Script" path="{RES}/flap_sprite.gd" id="2"]',
        f'[ext_resource type="Texture2D" path="{RES}/{png}.png" id="3"]',
        f'[ext_resource type="Script" path="{RES}/damage_fx.gd" id="4"]',
        '[ext_resource type="Shader" path="res://assets/shaders/hit_flash.gdshader" id="5"]',
    ]
    if name == "player":
        lines += [f'[ext_resource type="Script" path="{RES}/muzzle_flash.gd" id="6"]',
                  f'[ext_resource type="Texture2D" path="{RES}/projectiles/muzzle_flash.png" id="7"]']
    lines += [
        "", '[sub_resource type="ShaderMaterial" id="flash"]', "resource_local_to_scene = true",
        'shader = ExtResource("5")', "",
        '[sub_resource type="Gradient" id="spark_ramp"]',
        "offsets = PackedFloat32Array(0, 0.5, 1)",
        "colors = PackedColorArray(1, 0.96, 0.82, 1, 1, 0.62, 0.3, 1, 0.8, 0.3, 0.25, 0)", "",
        '[sub_resource type="Gradient" id="smoke_ramp"]',
        "colors = PackedColorArray(0.62, 0.58, 0.62, 0.75, 0.4, 0.36, 0.44, 0)", "",
        '[node name="Visual" type="Node2D"]', 'script = ExtResource("1")', f"neon_color = Color({neon})", "",
        '[node name="dusk_armada" type="Node2D" parent="."]', "texture_filter = 1", "",
        '[node name="Sprite" type="Sprite2D" parent="dusk_armada"]', 'material = SubResource("flash")',
        "scale = Vector2(2, 2)", 'texture = ExtResource("3")', f"hframes = {hframes}",
        'script = ExtResource("2")', f"fps = {fps}.0", f"anim_frames = {frames}", "",
        '[node name="DamageFx" type="Node2D" parent="dusk_armada" node_paths=PackedStringArray("sprite", "sparks", "smoke")]',
        'script = ExtResource("4")', 'sprite = NodePath("../Sprite")', 'sparks = NodePath("Sparks")',
        'smoke = NodePath("Smoke")',
    ]
    text = "\n".join(lines) + "\n" + PARTICLES + extra + "\n" + "\n".join(silhouette(polys))
    (ART / f"{name}.tscn").write_text(text.rstrip() + "\n")


def shot(name: str, png: str, frames: int, fps: int, neon: str, tint: str, glow_scale: str,
         y: int, polys: dict) -> None:
    lines = [
        "[gd_scene load_steps=6 format=3]", "",
        '[ext_resource type="Script" path="res://scenes/components/styled_visual.gd" id="1"]',
        f'[ext_resource type="Script" path="{RES}/flap_sprite.gd" id="2"]',
        f'[ext_resource type="Texture2D" path="{RES}/{png}.png" id="3"]',
        f'[ext_resource type="Texture2D" path="{RES}/projectiles/glow_round.png" id="4"]', "",
        '[sub_resource type="CanvasItemMaterial" id="add"]', "blend_mode = 1", "",
        '[node name="Visual" type="Node2D"]', 'script = ExtResource("1")', f"neon_color = Color({neon})", "",
        '[node name="dusk_armada" type="Node2D" parent="."]', "",
        '[node name="Glow" type="Sprite2D" parent="dusk_armada"]', "texture_filter = 2",
        'material = SubResource("add")', f"modulate = Color({tint})", f"scale = Vector2({glow_scale})",
        'texture = ExtResource("4")', "",
        '[node name="Sprite" type="Sprite2D" parent="dusk_armada"]', "texture_filter = 1",
        f"position = Vector2(0, {y})", "scale = Vector2(2, 2)", 'texture = ExtResource("3")',
        f"hframes = {frames}", 'script = ExtResource("2")', f"fps = {fps}.0", "",
    ] + silhouette(polys)
    (ART / f"{name}.tscn").write_text("\n".join(lines).rstrip() + "\n")


def main() -> None:
    for name, spec in SHIPS.items():
        ship(name, *spec)
    for name, spec in SHOTS.items():
        shot(name, *spec)
    print("wrote scenes under", ART)


if __name__ == "__main__":
    main()
