# 📖  Introduction
This repository **DotFiles** contain my personal config files. Here you'll find configs, customizations, themes, and whatever I need to personalize my Linux and MacOS experience. It takes the effort out of installing everything manually. Everything needed to install my preferred terminal setup is detailed in this readme. Feel free to explore, learn and copy parts for your own dotfiles. Enjoy!
The base of this repository uses Zsh as the base shell along with [Oh My Zsh](https://ohmyz.sh/) as the framework. I also use [Powerlevel10k](https://github.com/romkatv/powerlevel10k) as my theme. I have also included a few plugins that I use on a daily basis. You can find a list of all the plugins that I use below.

> :warning: Be aware, this product can change over time. I will do my best to keep this document up to date with the latest changes, but please understand that this won’t always be the case. 


# Installation 
Below are the two installation methods. The first is an automatic installation script that will install everything for you. The second is a manual installation method that will allow you to pick and choose what you want to install.
### Automatic Installation
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/realshaunoneill/dotfiles/master/install.sh)"
```

### Manual Installation
If you prefer to install everything manually, you can do so by following the steps below.
- Clone this repository to your home directory.
```sh
git clone https://github.com/realshaunoneill/dotfiles.git $HOME/.zsh
```
- Export the required environment variables that are needed for the initial installation.
```sh
echo "export ZDOTDIR=\$HOME/.zsh" >$HOME/.zshenv
echo "source \$ZDOTDIR/.zshenv" >>$HOME/.zshenv
```
- The final step is to change your default shell to zsh.
```sh
chsh -s $(which zsh)
zsh
```
And thats it! You should now have a fully functional zsh shell. You can read below to learn more about the features and customizations that are included in this repository.

# Plugins
There are a couple of plugins that are included by default. You can find a list of all the plugins below.
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)

# Contributions
If you’d like to contribute to this project, reach out to me on social media or [Discord](https://discord.gg/bz2SN7d), or create a pull request for the necessary changes.
