#!/usr/bin/env bash
touch $HOME/.vim
rm -rf $HOME/.vim
git clone https://github.com/XeliteXirish/Vim-Configs.git $HOME/.vim
cd $HOME/.vim && git submodule update --init
