#!/bin/bash

# ==============================================================================
# Shiny & Nerdy Workspace Installer
# Target: Ubuntu 24.04 / 26.04
# Installs: Neovim (LazyVim), Tmux (Catppuccin), Nerd Fonts, and Zsh Configs
# ==============================================================================

set -e # Exit on error

echo "🚀 Starting Workspace Installation..."

# 1. Update and Install System Dependencies
echo "📦 Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y \
    curl git unzip build-essential \
    ripgrep fd-find xclip wl-clipboard \
    zsh tmux fontconfig neovim

# 2. Setup Additional Utils
echo "🛠️ Setting up additional utilities..."
mkdir -p ~/.local/bin
ln -sf /usr/bin/fdfind ~/.local/bin/fd

# 3. Install JetBrains Mono Nerd Font
echo "🔡 Installing JetBrains Mono Nerd Font..."
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xvf JetBrainsMono.tar.xz
rm JetBrainsMono.tar.xz
fc-cache -fv
cd ~

# 4. Configure Neovim (LazyVim)
echo "✨ Setting up LazyVim..."
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Create the custom lualine config to remove the clock (as we moved it to tmux)
mkdir -p ~/.config/nvim/lua/plugins
cat << 'EOF' > ~/.config/nvim/lua/plugins/lualine.lua
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_z = {}
  end,
}
EOF

# 5. Configure Tmux (Catppuccin + TPM)
echo "🪟 Setting up Tmux..."
rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cat << 'EOF' > ~/.tmux.conf
# Fix colors for Neovim (TrueColor support)
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on

# Set prefix to Ctrl-Space
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix

# Plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'catppuccin/tmux'

# Catppuccin Theme Config (Sharp Corners)
set -g @catppuccin_flavor 'mocha'
set -g @catppuccin_window_status_style "basic"
set -g @catppuccin_status_left_separator  " █"
set -g @catppuccin_status_right_separator "█"
set -g @catppuccin_status_fill "icon"
set -g @catppuccin_status_connect_separator "no"

# Clock config
set -g @catppuccin_date_time_text " %H:%M"
set -g @catppuccin_date_time_icon "󱎫 "

# Status bar items
set -g status-right-length 100
set -g status-left-length 100
set -g status-left ""
set -g status-right "#{E:@catppuccin_status_application}"
set -ag status-right "#{E:@catppuccin_status_session}"
set -ag status-right "#{E:@catppuccin_status_date_time}"

# Convenient reload binding
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
EOF

# Install tmux plugins
~/.tmux/plugins/tpm/bin/install_plugins

# 6. Setup Zsh (Oh My Zsh + Optimized Config)
echo "🐚 Setting up Zsh..."
if [ ! -d ~/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting || true

# Update .zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

cat << 'EOF' >> ~/.zshrc
# Optimized Aliases & Paths
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
export PATH="$HOME/.local/bin:$PATH"

# Lazy Load NVM if it exists
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    nvm() { unset -f nvm node npm; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; nvm "$@"; }
    node() { unset -f nvm node npm; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node "$@"; }
    npm() { unset -f nvm node npm; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npm "$@"; }
fi
EOF

echo "✅ Installation Finished!"
echo "👉 Run 'zsh' to enter your new shell."
echo "👉 Remember to set your terminal font to 'JetBrainsMono Nerd Font'."
