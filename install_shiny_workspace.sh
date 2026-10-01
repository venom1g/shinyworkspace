#!/bin/bash

# ==============================================================================
# Shiny & Nerdy Workspace Installer
# Target: Ubuntu 24.04 / 26.04
# Installs: Neovim (LazyVim), Tmux (Catppuccin), Nerd Fonts, and Zsh Configs
# ==============================================================================

set -e # Exit on error

# --- Revert Logic ---
revert_changes() {
    echo "🔄 Reverting changes..."

    # 1. Remove Neovim PPA
    echo "🗑️ Removing Neovim PPA..."
    sudo add-apt-repository --remove ppa:neovim-ppa/unstable -y || true

    # 2. Uninstall Packages
    echo "📦 Uninstalling system dependencies..."
    sudo apt-get remove --purge -y \
        neovim tmux zsh fontconfig \
        ripgrep fd-find xclip wl-clipboard \
        build-essential unzip git curl \
        software-properties-common || true
    sudo apt-get autoremove -y || true

    # 3. Remove Neovim Config & Data
    echo "🌙 Cleaning up Neovim..."
    rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim

    # 4. Remove Tmux Config & Plugins
    echo "🪟 Cleaning up Tmux..."
    rm -rf ~/.tmux ~/.tmux.conf

    # 5. Remove Fonts
    echo "🔡 Removing Nerd Fonts..."
    rm -rf ~/.local/share/fonts/JetBrainsMono*
    fc-cache -fv || true

    # 6. Remove Zsh/Oh My Zsh
    echo "🐚 Cleaning up Zsh..."
    rm -rf ~/.oh-my-zsh
    
    # Remove the block from .zshrc
    if [ -f ~/.zshrc ]; then
        sed -i '/# SHINY_WORKSPACE_START/,/# SHINY_WORKSPACE_END/d' ~/.zshrc
    fi

    # 7. Clean up Bin
    rm -f ~/.local/bin/fd
    rm -f ~/.local/bin/nvim

    echo "✅ Revert Finished! Note: You may need to manually change your default shell back if you changed it."
    exit 0
}

# Check for revert flag
if [[ "$1" == "--revert" ]]; then
    revert_changes
fi

echo "🚀 Starting Workspace Installation..."

# 1. Update and Install System Dependencies
echo "📦 Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:neovim-ppa/unstable -y
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

# Debian/Ubuntu ship the bundled treesitter parsers (vimdoc, lua, ...) under the
# multiarch dir /usr/lib/<arch>/nvim, which lazy.nvim drops when it resets the rtp.
# Without this, plugin installs fail with: No parser for language "vimdoc"
sed -i 's|^\(\s*\)rtp = {$|&\n\1  paths = vim.fn.glob("/usr/lib/*/nvim", false, true),|' ~/.config/nvim/lua/config/lazy.lua
grep -q 'paths = vim.fn.glob("/usr/lib/\*/nvim"' ~/.config/nvim/lua/config/lazy.lua \
    || echo "⚠️ Could not patch lazy.lua rtp paths; you may see 'No parser for language \"vimdoc\"'."

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
cat << 'EOF' >> ~/.zshrc

# SHINY_WORKSPACE_START
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
# SHINY_WORKSPACE_END
EOF

# Add plugins to .zshrc if not already there
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

echo "✅ Installation Finished!"
echo "👉 Run 'zsh' to enter your new shell."
echo "👉 Remember to set your terminal font to 'JetBrainsMono Nerd Font'."
