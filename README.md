# Godot 4 – Lightweight Voxel Terrain Generator

This project is a voxel-based terrain generator built in **Godot 4**, using `MultiMeshInstance3D` for highly optimized rendering.  
It includes procedural generation with **Perlin noise**, basic **block type logic**, and **collision support** using `SurfaceTool`.

Please consider this more as a prototype than a finished project. Many features are still missing, such as caves, a chunk system, destructible blocks, and biome management.
---


https://github.com/user-attachments/assets/beadc38d-256e-45d2-be22-bf67f12a6d1c


## ✨ Features

- Procedural terrain generation using `NoiseTexture2D`
- Multiple block types (grass, dirt, stone, sand, water)
- Face culling: only visible blocks are rendered
- Fast rendering with `MultiMeshInstance3D`
- Static collision generation using `SurfaceTool` and `ConcavePolygonShape3D`
- Simple gravity/physics example
