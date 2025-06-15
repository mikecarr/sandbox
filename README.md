# sandbox





## Shells Scripts

* Simple : simple bash

```bash
# Using curl:
curl -sSL https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/simple.sh | bash


# Using wget:
wget -qO - https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/simple.sh | bash
```

* Zsh with Starship
* 
```bash
# Using curl:
curl -sSL https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/setup-zsh-starship.sh | bash


# Using wget:
wget -qO - https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/setup-zsh-starship.sh | bash
```

## Complete

### Install all development tools
```
wget -qO - https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/install-dev-tools.sh | bash
```

### Install Neovim + LazyVim (depends on dev tools)
```
wget -qO - https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/install-neovim-robust.sh | bash
```

### Install shell enhancements
```
wget -qO - https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/install-starship-zsh.sh | bash
```
     
