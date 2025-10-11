# SiImpactControl

## TL;DR

This software enables control of the **Si Impact** digital mixer from devices other than the first-party **ViSi Remote** app.  
It does this using a custom implementation of the **HiQNet** network protocol ([see my implementation](https://github.com/SpectrumPro/godot-hiqnet)), developed in the **Godot** game engine.

## Introduction

The **Soundcraft Si Impact** is a *horrible* mixer. Once you get used to it, you really start to understand how they built the thing, which was most likely made using spare parts they fished out of the dumpster behind **Allen & Heath’s** HQ.  

Using this mixer feels like operating an analog console... but with a pair of chopsticks. You could probably get better sound quality out of smashing two rocks together and hoping it EQs the kick drum for you.  

But I’m stuck using the thing...

The Impact has a built-in cue list however, it’s extremely limited and incredibly fiddly to program. There’s also zero support for external control of this cue list, making it impossible to link with external systems like **QLab**.  
That’s why I created this software.

## How It Works

This software connects to the **Si Impact** via **HiQNet**, Harman’s proprietary network protocol used across their networked audio devices ([official docs here](https://audioarchitect.harmanpro.com/resource/audio-architect-hiqnet-third-party-programmers-guide.pdf)).  
To make this possible, I developed a custom implementation of HiQNet inside the **Godot** game engine ([see my implementation](https://github.com/SpectrumPro/godot-hiqnet)).

Once connected to the console, it allows control of all faders on the desk, as well as any parameter controllable over HiQNet, like channel EQ, pan, and dynamics.  
But not the built-in cue list, that’s why this software comes with a built-in cue list, which allows you to program values that are sent to the console with each cue.

I’ve used this software in three different theatrical productions, including two junior musicals.  
In my workflow, I integrate it with **QLab** to control mixer cues at the same time as triggering SFX.

## Features

- Connect to any **Soundcraft Si Impact** mixer  
- Control mute and fader of any channel  
- Integrated cue list allows control of any network-available parameter on the console  
- Integration with **QLab** over OSC for external control  
- WIP: Control of channel parameters inside the application (EQ, dynamics, etc.)

## Limitations

- Currently, this software only supports the **Si Impact** mixer running firmware version 2.0 or above. In theory, this program could support any HiQNet-enabled mixer due to the architecture of how it was created. However, as I only have access to an Impact, it is limited to that.  
- As of now, there is no GUI for editing channel parameters, though this is planned.  
- Not every parameter can be controlled from the software’s built-in cue list. Things like patching, VCA or mute group assignment, and the mute groups themselves cannot be controlled over the network at all, not even from the official iPad app.
- Currently, only supports the STRING, and LONG data types in HiQnet.

## Credits

The development of this project was inspired and aided by the work of [EMATech's HiQontrol](https://github.com/EMATech/HiQontrol).

---

© 2025 Liam Sherwin — [liamsherwin.com](https://liamsherwin.com)  
Licensed under **GPLv3 or later**
