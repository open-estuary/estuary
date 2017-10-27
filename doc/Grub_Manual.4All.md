* [Introduction](#1)
* [Grub config file](#2)
* [FAQ](#3)

## <a name="1">Introduction</a>

Grub is a kind of boot loader to load kernel into RAM and run it.

After rebooting board every time, the UEFI will firstly try to download the grub binary and run it firstly.

Then grub binary will load the kernel and start it with cmdline according to the configurations in `grub.cfg`.

They include:
```bash
grubaa64.efi    # The grub binary executable program for ARM64 architecture
grub.cfg        # The grub config file which will be used by grub binary
```
Where to get them, please refer to Readme.txt.

## <a name="2">Grub config file</a>

You can edit a `grub.cfg` file to support various boot mode or multi boot partitions, follow is an example.

You should change them according to your real local environment.

set menu_color_normal=cyan/blue
set menu_color_highlight=white/blue

menuentry 'Install' {
    set background_color=black
    linux    /debian-installer/arm64/linux --- quiet
    initrd   /debian-installer/arm64/initrd.gz
}
submenu 'Advanced options ...' {
    set menu_color_normal=cyan/blue
    set menu_color_highlight=white/blue
    menuentry '... Expert install' {
        set background_color=black
        linux    /debian-installer/arm64/linux priority=low ---
        initrd   /debian-installer/arm64/initrd.gz
    }
    menuentry '... Rescue mode' {
        set background_color=black
        linux    /debian-installer/arm64/linux rescue/enable=true --- quiet
        initrd   /debian-installer/arm64/initrd.gz
    }
    menuentry '... Automated install' {
        set background_color=black
        linux    /debian-installer/arm64/linux auto=true priority=critical --- quiet
        initrd   /debian-installer/arm64/initrd.gz
    }
    submenu '... Desktop environment menu ...' {
        set menu_color_normal=cyan/blue
        set menu_color_highlight=white/blue
        submenu '... GNOME desktop boot menu ...' {
            set menu_color_normal=cyan/blue
            set menu_color_highlight=white/blue
            menuentry '... Install' {
                set background_color=black
                linux    /debian-installer/arm64/linux desktop=gnome --- quiet
                initrd   /debian-installer/arm64/initrd.gz
            }
            submenu '... GNOME advanced options ...' {
                set menu_color_normal=cyan/blue
                set menu_color_highlight=white/blue
                menuentry '... Expert install' {
                    set background_color=black
                    linux    /debian-installer/arm64/linux desktop=gnome priority=low ---
                    initrd   /debian-installer/arm64/initrd.gz
                }
                menuentry '... Automated install' {
                    set background_color=black
                    linux    /debian-installer/arm64/linux desktop=gnome auto=true priority=critical --- quiet
                    initrd   /debian-installer/arm64/initrd.gz
                }
            }
            menuentry '... Install with speech synthesis' {
                set background_color=black
                linux    /debian-installer/arm64/linux desktop=gnome speakup.synth=soft --- quiet
                initrd   /debian-installer/arm64/initrd.gz
            }
        }
        submenu '... KDE desktop boot menu ...' {
            set menu_color_normal=cyan/blue
            set menu_color_highlight=white/blue
            menuentry '... Install' {
                set background_color=black
                linux    /debian-installer/arm64/linux desktop=kde --- quiet
                initrd   /debian-installer/arm64/initrd.gz
            }
            submenu '... KDE advanced options ...' {
                set menu_color_normal=cyan/blue
                set menu_color_highlight=white/blue
                menuentry '... Expert install' {
                    set background_color=black
                    linux    /debian-installer/arm64/linux desktop=kde priority=low ---
                    initrd   /debian-installer/arm64/initrd.gz
                }
                menuentry '... Automated install' {
                    set background_color=black
                    linux    /debian-installer/arm64/linux desktop=kde auto=true priority=critical --- quiet
                    initrd   /debian-installer/arm64/initrd.gz
                }
            }
            menuentry '... Install with speech synthesis' {
                set background_color=black
                linux    /debian-installer/arm64/linux desktop=kde speakup.synth=soft --- quiet
                initrd   /debian-installer/arm64/initrd.gz
            }
        }
        submenu '... LXDE desktop boot menu ...' {
            set menu_color_normal=cyan/blue
            set menu_color_highlight=white/blue
            menuentry '... Install' {
                set background_color=black
                linux    /debian-installer/arm64/linux desktop=lxde --- quiet
                initrd   /debian-installer/arm64/initrd.gz
            }
            submenu '... LXDE advanced options ...' {
                set menu_color_normal=cyan/blue
                set menu_color_highlight=white/blue
                menuentry '... Expert install' {
                    set background_color=black
                    linux    /debian-installer/arm64/linux desktop=lxde priority=low ---
                    initrd   /debian-installer/arm64/initrd.gz
                }
                menuentry '... Automated install' {
                    set background_color=black
                    linux    /debian-installer/arm64/linux desktop=lxde auto=true priority=critical --- quiet
                    initrd   /debian-installer/arm64/initrd.gz
                }
            }
            menuentry '... Install with speech synthesis' {
                set background_color=black
                linux    /debian-installer/arm64/linux desktop=lxde speakup.synth=soft --- quiet
                initrd   /debian-installer/arm64/initrd.gz
            }
        }
    }
}
menuentry --hotkey=s 'Install with speech synthesis' {
    set background_color=black
    linux    /debian-installer/arm64/linux speakup.synth=soft --- quiet
    initrd   /debian-installer/arm64/initrd.gz
}

## <a name="3">FAQ</a>

If you want to modify `grub.cfg` command line temporarily. Type "E" key into grub modification menu. You will face problem that the "backspace" key not woking properly. You can fix backspace issue by changing terminal emulator's configuration.

**For gnome-terminal**: Open "Edit" menu, select "Profile preferences".
In "Compatibility" page, select "Control-H" in "Backspace key generates" listbox.
**For Xterm**: press Ctrl key and left botton of mouse, and toggle on "Backarrow key (BS/DEL)" in mainMenu.
