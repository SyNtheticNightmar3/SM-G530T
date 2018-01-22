#!/sbin/sh
#
# This software is licensed under the terms of the GNU General Public
# License version 2, as published by the Free Software Foundation, and
# may be copied, distributed, and modified under those terms.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Please maintain this if you use this script or any part of it

pbs=/system/etc/init.qcom.post_boot.sh

# Append for per-process reclaim
cp $pbs $pbs.bck
echo "" >> $pbs
echo "echo 1 > /sys/module/process_reclaim/parameters/enable_process_reclaim" >> $pbs
echo "echo 50 > /sys/module/process_reclaim/parameters/pressure_min" >> $pbs
echo "echo 70 > /sys/module/process_reclaim/parameters/pressure_max" >> $pbs
echo "echo 512 > /sys/module/process_reclaim/parameters/per_swap_size" >> $pbs
echo "echo 30 > /sys/module/process_reclaim/parameters/swap_opt_eff" >> $pbs
