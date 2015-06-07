mkdir -p /home/olpc/{Activities,Library}
chown olpc:olpc /home/olpc/{Activities,Library}

shopt -s nullglob
for i in /build_shared/sugar-bundles/*; do
	if [ "${i:(-4)}" == ".xol" ]; then
		/usr/bin/unzip -d /home/olpc/Library -q $i
	else
		/bin/su -c "/usr/bin/sugar-install-bundle $i" - olpc > /dev/null
	fi
done
shopt -u nullglob
#/bin/su -c "/bin/olpc-library-update" - olpc > /dev/null

chown -R olpc:olpc /home/olpc/{Activities,Library}
