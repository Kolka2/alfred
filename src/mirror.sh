#!/bin/sh
#
# General purpose syncing script
# Dependencies: git, rclone, unison
# mirror --[git,calcurse,phone,arch,repos,upstream]

LOCAL=/mnt/horcrux
CLOUD=drive

if ! connected; then
   # notify-send -t 3000 -i "$ICONS"/disconnected.png "Coudn't mirror"
   exit 1
fi

# notify-send -i "$ICONS/mirror.png" "Mirroring now"

while :; do
   case $1 in

      --mail | -m) mbsync -c ~/.config/isync/mbsyncrc -a ;;

      --git | -g)
         #weechat
         cp -fr /home/internal/weechat "$GIT"/own/magpie-private/.config

         for dir in "$GIT"/own/*/ "$GIT"/suckless/*/; do
            cd "$dir" || continue
            # git pull --no-rebase
            git add .
            [ -z "$(git status --porcelain)" ] && continue
            [ "${PWD##*/}" = magpie-private ] ||
               [ "${PWD##*/}" = magpie-archived ] ||
               message=$(timeout 15 sh -c " : | $DMENU -p $(echo $PWD | awk -F / '{print $NF}')")
            if [ -z "$message" ]; then
               git commit -C HEAD --reset-author && git push
            else
               git commit -m "$message" && git push
            fi
         done
         ;;

      --calcurse | -c)
         CALCURSE_CALDAV_PASSWORD=$(gpg -d ~/.local/share/passwords/salmanabedin@disroot.org.gpg) calcurse-caldav
         # --init=keep-remote
         ;;

      --arch | -a)
         doas -- pacman -Syyu --noconfirm
         yay -Syu --noconfirm
         npm update -g
         ;;

      --phone | -p)
         ANDROID=/mnt/phone
         LOCAL=/mnt/horcrux/phone
         if ! timeout 3 sshfs -p "$PORT" "$CARD" "$ANDROID"; then
            notify-send -t 3000 -i "$ICONS"/critical.png "Couldn't sync phone!" && exit 1
         fi
         unison -batch -fat "$ANDROID" "$LOCAL"
         fusermount -u "$ANDROID"
         ;;

      --repos | -r)
         for dir in "$GIT"/others/*/; do
            [ -d "$dir" ] && git -C "$dir" pull --rebase
         done
         ;;

      --upstream | -u)
         for dir in "$GIT"/forks/*/; do
            if [ -d "$dir" ]; then
               cd "$dir" || exit
               git fetch upstream
               git rebase upstream/master
            fi
         done
         ;;

      --dots | -d)
         WEECHAT_ROOT=$GIT/own/magpie/.config/weechat
         WEECHAT_PRIVATE=$GIT/own/magpie-private/.config/weechat
         WEECHAT_CLONE=/home/salman/.config/weechat

         find "$WEECHAT_ROOT" -maxdepth 1 -type f |
            sed 's/\/mnt\/horcrux\/git\/own\/magpie/\/home\/salman/' |
            xargs cp -ft "$WEECHAT_ROOT"

         find "$WEECHAT_PRIVATE" -maxdepth 1 -type f |
            sed 's/\/mnt\/horcrux\/git\/own\/magpie-private/\/home\/salman/' |
            xargs cp -ft "$WEECHAT_PRIVATE"

         cp -frs -t ~ \
            "$GIT"/own/magpie/. \
            "$GIT"/own/magpie-private/.

         find "$WEECHAT_CLONE" -maxdepth 1 -type l -delete
         find "$WEECHAT_ROOT" "$WEECHAT_PRIVATE" -maxdepth 1 -type f |
            xargs cp -ft /home/salman/.config/weechat

         doas -- find ~ -xtype l -delete
         rm ~/LICENSE ~/README.md ~/.gitignore

         ;;

      --drive | -D)

         rclone sync $LOCAL/documents $CLOUD:documents
         rclone sync $LOCAL/notes $CLOUD:notes
         rclone sync $LOCAL/library $CLOUD:library

         rclone sync "$GIT"/others $CLOUD:git/others
         rclone sync "$GIT"/forks $CLOUD:git/forks
         rclone sync "$GIT"/archived $CLOUD:git/archived
         ;;

         --firefox | -f)
         LOCAL=/mnt/horcrux
         CLOUD=drive
         FIREFOX_PROFILE=zmzk0pef.default-release
         FIREFOX_LOCAL=$LOCAL/firefox

         # cd /tmp || exit
         # rclone copy $CLOUD:$FIREFOX_PROFILE.tar.gpg ~
         # gpg -o $FIREFOX_PROFILE.tar -d $FIREFOX_PROFILE.tar.gpg
         # tar xf $FIREFOX_PROFILE.tar
         # unison -batch $FIREFOX_LOCAL/$FIREFOX_PROFILE $FIREFOX_PROFILE
         # rm $FIREFOX_PROFILE.tar $FIREFOX_PROFILE.tar.gpg $FIREFOX_PROFILE

         cd $FIREFOX_LOCAL || exit
         tar cf $FIREFOX_PROFILE.tar $FIREFOX_PROFILE
         gpg -esr "$MAIL" $FIREFOX_PROFILE.tar
         rclone copy $FIREFOX_PROFILE.tar.gpg $CLOUD:/
         rm $FIREFOX_PROFILE.tar $FIREFOX_PROFILE.tar.gpg
         ;;

      \
         *) break ;;
   esac
   shift
done
# wait
# notify-send -i "$ICONS/mirror.png" "Done mirroring"

#===============================================================================
#                             Exp
#===============================================================================

# --brave | -b)
#    cd ~/.config || exit
#    tar cf Brave.tar BraveSoftware
#    gpg -esr "$MAIL" Brave.tar
#    rclone copy Brave.tar.gpg $CLOUD:/
#    rm Brave.tar Brave.tar.gpg
#    ;;

# --firefox | -f)
# rsync -a --delete ~/.mozilla/firefox/"$FIREFOXPROFILE".default-release \
#    "$GIT"/own/firefox/.mozilla/firefox
# ~/.mozilla/firefox/"$FIREFOXPROFILE".default-release
# curl -T firefox.tar.gz \
# -u "salmanabedin@disroot.org:$(gpg -d --batch --passphrase asdlkj \
# ~/.local/share/passwords/salmanabedin@disroot.org.gpg)" \
# https://cloud.disroot.org/remote.php/dav/files/salmanabedin/
# ;;

# --newsboat | -n)
# newsboat -x reload
# pgrep -f newsboat$ && /usr/bin/xdotool key --window "$(/usr/bin/xdotool search --name newsboat)" R && exit
# ;;
# umount -l /mnt/cloud

# --mail | -m)
#    mbsync -c ~/.config/isync/mbsyncrc -a
#    unread=$(find ~/.local/share/mail/INBOX/new/* -type f 2> /dev/null | wc -l)
#    [ "$unread" -gt 0 ] && notify-send -t 0 -i "$ICONS/mail.png" \
#    "You've got $unread new mail!"
#    ;;
