# **TWRP Helper**

## Introduction

This module provides dynamic, in-situ patching of the device's
[TWRP](https://twrp.me/) recovery image to include so-called **Internal
Storage** in future **Data** back-ups.

**Internal Storage** is the somewhat confusing name given to the emulated
internal SD card used to store your downloads, game data and media files;
such as photos, videos, music and more. By default, [TWRP excludes **Internal
Storage**](https://twrp.me/faq/backupexclusions.html) when backing up **Data**
and there is currently no setting that allows you to include it. This makes it
impossible to conduct a full back-up without resorting to TWRP's Terminal
module to manually back-up `/data/media` with `tar`.

If this manual back-up isn't performed, whether due to inertia, forgetfulness
or user error, a considerable amount of data can be exposed to the risk of
loss.

As a simple example, my own Samsung Galaxy S10+ shows the following data under
`/data/media`:

```
beyond2:/ # ls /data/media/{0,obb}
/data/media/0:
ACRCalls   LastPassAuthenticator Signal             WhatsApp
AMap       Music                 Snapseed           data
Android    Pictures              TWRP               dslv_state.txt
DCIM       Playlists             Tasker             log
Download   Recordings            Telegram           switch-recovery
ElementalX Ringtones             ViPER4Android
Kustom     Samsung               Web\ Video\ Caster

/data/media/obb:
amanita_design.samorost3.GP                com.toppluva.grandmountain
com.brainbow.peak.app                      com.ubisoft.hungrysharkworld
com.colorswitch.switch2                    com.ustwo.monumentvalley2
com.elevenbitstudios.twommobile            it.mvilla.android.fenix2
com.etermax.trivia.preguntados2            jp.co.taito.groovecoasterzero
com.imangi.templerun2                      net.osmand.plus
com.kiloo.subwaysurf                       pl.idreams.SkyForceReloaded2016
com.nexonm.aftertheend                     se.maginteractive.rumble
com.squareenixmontreal.hitmansniperandroid

beyond2:/ # du -sh /data/media
6.7G	/data/media
```

That's 6.7 Gb of data that TWRP simply cannot be configured to back-up.

This module eliminates the user's exposure by modifying TWRP to remove the
exclusion of `/data/media` from **Data** back-ups.

## Installation

When you use Magisk Manager to install the module, the module will
immediately attempt to patch your device's recovery. The app's console will
clearly indicate success or failure.

Failure to find a patchable image during module installation is non-fatal,
because the image in your recovery partition isn't static: It may be updated
to a patchable image at some later point in time. In this scenario, the module
will still be installed to allow for the possibility of future patching.

On subsequent reboots to rooted Android, the module will reinspect the
recovery partition. If a suitable TWRP recovery image is found, it will be
patched at this time.

A log of this process (`twrp-helper.log`) will be saved in the module's own
directory (`/data/adb/modules/twrp-helper` at the time of writing). This can
be read from a connected computer during or after boot, using
[adb](https://www.xda-developers.com/install-adb-windows-macos-linux/) as
follows:

`adb shell su -c cat /data/adb/modules/twrp-helper/twrp-helper.log`

If patching was successful, a copy of the patched TWRP image file
(`twrp-patched.img`) will be saved in the module's own directory. If the path
`/storage/emulated/0/Download` is available (which it typically **isn't** when
the module's service script is run during boot), the image will be moved here
for easy access.

Inspecting the recovery partition on each boot takes just a fraction of a
second. If the recovery image requires patching, the process will take several
seconds (most of which is the repacking of the new image), but because the
work is performed in late start service mode, which is non-blocking, it will
be done in parallel with other boot tasks and therefore have a negligible
impact on boot duration.

## Description

Once you have a successfully patched TWRP recovery image, you can reboot to
TWRP and make immediate use of the augmented functionality.

Set your language to _English_ and select the **Backup** module from the main
menu and you should now see **Data** annotated with **(incl. storage)**, where
formerly the text **(excl. storage)** would have appeared.

Back-ups of **Data** will thus henceforth include **Internal Storage**
(`/data/media`). Analogously, wiping **Data** will subsequently also wipe
**Internal Storage**. This has two critical ramifications.

Firstly, if you back up to **Internal Storage**, any back-up you make of
**Data** will now include nested copies of all of your existing back-ups. This
is probably not what you want and will quickly spiral out of control until all
of the available storage space has been consumed.

Secondly, since a restore operation is preceded by a wipe, any TWRP back-ups
residing on **Internal Storage** will be **deleted** when you restore
**Data**. If you are not careful, you could easily destroy the very back-up
you are attempting to restore.

For the above two reasons, you are strongly advised to back up only to an
external SD card from this point forward.

Note that a **Data** back-up made by a patched TWRP does **not** require a
patched TWRP to restore it. Standard TWRP will **not** wipe `/data/media`
before restoring to it.

## Uninstallation

When you mark the module for removal in Magisk Manager, the module will
inspect the recovery partition one final time during the next boot of the
device to rooted Android. If a previously patched image of TWRP is found, it
will be reverse-patched to return it to its former state.

A log of this process (`twrp-helper.log`) will be saved in Magisk's module
container directory (`/data/adb/modules` at the time of writing). The log of
the unpatching process cannot be saved in the module's own directory, since
this is removed during the module's uninstallation. Although leaving a remnant
behind on the file-system following uninstallation is contrary to good
housekeeping, the need to know what actions were performed by the module
before its removal takes precedence over this concern.

## Bugs and Shortcomings

* Only the English language strings are patched to reflect the inclusion of
  **Internal Storage** in **Data** back-ups. If you use TWRP in a language
  other than English, your back-ups will still include **Internal Storage**,
  but the messages displayed by TWRP will be misleading.

* For reasons that have yet to be ascertained, uninstallation of the module
  currently results in the reverse-patching of the TWRP image being attempted
  twice. The first attempt is successful and returns the image to its former
  state, but the log of this is then overwritten by a second, unsuccessful
  attempt. Bear this in mind when viewing the uninstallation log and trying to
  reconcile the messages here with the actual state of the device's recovery
  partition.

* The module requires Magisk v19 or later.

## Warranty and Disclaimer

This module is offered *as is* without warranty or support of any kind, either
expressed or implied, including, but not limited to, the implied warranties of
merchantability and fitness for a particular purpose. By using this module,
you assume sole responsibility for its performance on your device.

The module has been tested on Samsung S10 (G973F) and S10+ (G975F) devices
running TWRP 3.3.1, where it performed as expected. Although the module has
**not** been tested on **any other** model of device, it is likely to work on
many devices with a standard A-only partition configuration.

However, no effort whatsoever has been made to accommodate [devices with an
A/B partitioning
scheme](https://www.xda-developers.com/how-a-b-partitions-and-seamless-updates-affect-custom-development-on-xda/).
Although I think I know what would be required to support such devices, I do
not own such a device, have no experience with such a device and cannot test
on such a device. I would, however, be happy to receive patches.

## Changelog

2019-06-10: v1.0

- Initial release.

## Links

* TWRP FAQ: [What is a data/media device?](https://twrp.me/faq/datamedia.html)

* TWRP FAQ: [What is excluded from a TWRP
  backup?](https://twrp.me/faq/backupexclusions.html)

* The long-running (5+ years, in spite of closure) [GitHub
  issue](https://github.com/TeamWin/Team-Win-Recovery-Project/issues/276)
  requesting that TWRP support the inclusion of `/data/media` in **Data**
  back-ups.

* [Rationale
  1](https://github.com/TeamWin/Team-Win-Recovery-Project/issues/276#issuecomment-239172861)
  and [rationale
  2](https://github.com/TeamWin/Team-Win-Recovery-Project/issues/276#issuecomment-246113375)
  for TWRP's exclusion of `/data/media`.
