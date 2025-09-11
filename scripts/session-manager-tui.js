#!/usr/bin/env node

/**
 * TTY Session Manager - Blessed.js Edition
 * Proper terminal interface inspired by alpha-mission-center
 * But actually useful for session management!
 */

const blessed = require('blessed');
const { execSync, spawn } = require('child_process');
const fs = require('fs');
const os = require('os');

class SessionManagerTUI {
    constructor() {
        this.dotfilesDir = process.env.HOME + '/.dotfiles';
        this.screen = blessed.screen({
            smartCSR: true,
            title: 'Session Manager TUI'
        });
        
        this.desktops = [];
        this.tools = [];
        this.currentFocus = 'desktops';
        
        this.init();
    }

    init() {
        this.detectDesktops();
        this.detectTools();
        this.createInterface();
        this.bindKeys();
        this.screen.render();
    }

    // Detect available desktop environments
    detectDesktops() {
        const desktops = [
            { id: '1', name: 'KDE Plasma (Wayland)', cmd: 'startplasma-wayland', check: 'startplasma-wayland' },
            { id: '2', name: 'Sway', cmd: 'sway', check: 'sway' },
            { id: '3', name: 'Hyprland', cmd: 'Hyprland', check: 'Hyprland' },
            { id: '4', name: 'COSMIC Desktop', cmd: 'cosmic-session', check: 'cosmic-session' },
            { id: '5', name: 'XFCE', cmd: 'startx /usr/bin/startxfce4', check: 'startxfce4' },
            { id: '6', name: 'i3 (X11)', cmd: 'startx /usr/bin/i3', check: 'i3' }
        ];

        this.desktops = desktops.filter(desktop => this.commandExists(desktop.check));
    }

    // Detect available CLI tools
    detectTools() {
        const tools = [
            { key: 'c', name: 'Calendar (calcurse)', cmd: 'calcurse', check: 'calcurse' },
            { key: 't', name: 'Tasks (taskwarrior-tui)', cmd: 'taskwarrior-tui', check: 'taskwarrior-tui' },
            { key: 'b', name: 'System Monitor (btop)', cmd: 'btop', check: 'btop' },
            { key: 'r', name: 'File Manager (ranger)', cmd: 'ranger', check: 'ranger' },
            { key: 'v', name: 'Neovim Editor', cmd: 'nvim', check: 'nvim' }
        ];

        this.tools = tools.filter(tool => this.commandExists(tool.check));
    }

    // Check if command exists
    commandExists(cmd) {
        try {
            execSync(`command -v ${cmd}`, { stdio: 'ignore' });
            return true;
        } catch {
            return false;
        }
    }

    // Get system information
    getSystemInfo() {
        try {
            const hostname = os.hostname();
            const uptime = execSync('uptime -p').toString().trim();
            const load = execSync("uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'").toString().trim();
            const memory = execSync("free | awk '/^Mem:/ {printf \"%.1f\", $3/$2 * 100.0}'").toString().trim();
            
            return {
                hostname,
                uptime,
                load: parseFloat(load) || 0,
                memory: parseFloat(memory) || 0
            };
        } catch {
            return {
                hostname: 'unknown',
                uptime: 'unknown',
                load: 0,
                memory: 0
            };
        }
    }

    // Create the blessed.js interface
    createInterface() {
        const sysInfo = this.getSystemInfo();

        // Header box
        this.headerBox = blessed.box({
            top: 0,
            left: 0,
            width: '100%',
            height: 6,
            content: this.getHeaderContent(sysInfo),
            border: {
                type: 'line',
                style: {
                    fg: 'cyan'
                }
            },
            style: {
                fg: 'white',
                bg: 'black',
                border: {
                    fg: 'cyan'
                }
            },
            tags: true
        });

        // Desktop environments box
        this.desktopBox = blessed.box({
            label: ' {bold}Desktop Environments{/bold} ',
            top: 6,
            left: 0,
            width: '50%',
            height: Math.max(this.desktops.length + 4, 10),
            content: this.getDesktopContent(),
            border: {
                type: 'heavy'
            },
            style: {
                fg: 'white',
                bg: 'black',
                border: {
                    fg: this.currentFocus === 'desktops' ? 'yellow' : 'gray'
                }
            },
            scrollable: true,
            tags: true
        });

        // CLI tools box
        this.toolsBox = blessed.box({
            label: ' {bold}CLI Tools{/bold} ',
            top: 6,
            left: '50%',
            width: '50%',
            height: Math.max(this.tools.length + 4, 10),
            content: this.getToolsContent(),
            border: {
                type: 'heavy'
            },
            style: {
                fg: 'white',
                bg: 'black',
                border: {
                    fg: this.currentFocus === 'tools' ? 'yellow' : 'gray'
                }
            },
            scrollable: true,
            tags: true
        });

        // Actions box
        this.actionsBox = blessed.box({
            label: ' {bold}System Actions{/bold} ',
            top: Math.max(this.desktops.length, this.tools.length) + 10,
            left: 0,
            width: '100%',
            height: 9,
            content: this.getActionsContent(),
            border: {
                type: 'heavy'
            },
            style: {
                fg: 'white',
                bg: 'black',
                border: {
                    fg: this.currentFocus === 'actions' ? 'yellow' : 'gray'
                }
            },
            tags: true
        });

        // Status/Help box
        this.statusBox = blessed.box({
            label: ' {bold}Help & Status{/bold} ',
            bottom: 0,
            left: 0,
            width: '100%',
            height: 5,
            content: this.getStatusContent(),
            border: {
                type: 'heavy'
            },
            style: {
                fg: 'cyan',
                bg: 'black',
                border: {
                    fg: 'cyan'
                }
            },
            tags: true
        });

        // Add all boxes to screen
        this.screen.append(this.headerBox);
        this.screen.append(this.desktopBox);
        this.screen.append(this.toolsBox);
        this.screen.append(this.actionsBox);
        this.screen.append(this.statusBox);
    }

    // Generate header content
    getHeaderContent(sysInfo) {
        const loadColor = sysInfo.load > 2.0 ? '{red-fg}' : sysInfo.load > 1.0 ? '{yellow-fg}' : '{green-fg}';
        const memColor = sysInfo.memory > 80 ? '{red-fg}' : sysInfo.memory > 60 ? '{yellow-fg}' : '{green-fg}';
        
        return `{center}{bold}═══════════════════════════════════════════════════════════════════{/bold}{/center}\n` +
               `{center}{bold}║                    TTY SESSION MANAGER v4.0-TUI                   ║{/bold}{/center}\n` +
               `{center}{bold}═══════════════════════════════════════════════════════════════════{/bold}{/center}\n` +
               `{center}Host: {cyan-fg}{bold}${sysInfo.hostname}{/bold}{/cyan-fg} │ Up: {blue-fg}${sysInfo.uptime}{/blue-fg} │ Load: ${loadColor}${sysInfo.load}{/} │ RAM: ${memColor}${sysInfo.memory}%{/}{/center}`;
    }

    // Generate desktop environments content
    getDesktopContent() {
        if (this.desktops.length === 0) {
            return '\n  {red-fg}No desktop environments detected{/red-fg}\n  {gray-fg}Install KDE, Sway, Hyprland, etc.{/gray-fg}\n';
        }

        let content = '\n';
        this.desktops.forEach(desktop => {
            const highlight = this.currentFocus === 'desktops' ? '{white-bg}{black-fg}' : '{cyan-fg}';
            const reset = this.currentFocus === 'desktops' ? '{/black-fg}{/white-bg}' : '{/cyan-fg}';
            content += `  ${highlight}[${desktop.id}]${reset} {bold}${desktop.name}{/bold}\n`;
        });
        
        content += '\n  {yellow-fg}Press number to launch desktop{/yellow-fg}';
        return content;
    }

    // Generate CLI tools content
    getToolsContent() {
        if (this.tools.length === 0) {
            return '\n  {red-fg}No CLI tools detected{/red-fg}\n  {gray-fg}Install calcurse, btop, ranger, etc.{/gray-fg}\n';
        }

        let content = '\n';
        this.tools.forEach(tool => {
            const highlight = this.currentFocus === 'tools' ? '{white-bg}{black-fg}' : '{green-fg}';
            const reset = this.currentFocus === 'tools' ? '{/black-fg}{/white-bg}' : '{/green-fg}';
            content += `  ${highlight}[${tool.key}]${reset} {bold}${tool.name}{/bold}\n`;
        });
        
        content += '\n  {yellow-fg}Press letter to launch tool{/yellow-fg}';
        return content;
    }

    // Generate system actions content
    getActionsContent() {
        const highlight = this.currentFocus === 'actions' ? '{white-bg}{black-fg}' : '{magenta-fg}';
        const reset = this.currentFocus === 'actions' ? '{/black-fg}{/white-bg}' : '{/magenta-fg}';
        
        return '\n' +
               `  ${highlight}[R]${reset} {bold}Recovery Wizard{/bold}        ${highlight}[S]${reset} {bold}System Status{/bold}\n` +
               `  ${highlight}[T]${reset} {bold}Telegram Setup{/bold}         ${highlight}[F]${reset} {bold}Fast Mode{/bold}\n` +
               `  ${highlight}[B]${reset} {bold}Bash Fallback{/bold}          ${highlight}[I]${reset} {bold}System Info{/bold}\n` +
               '\n' +
               '  {yellow-fg}Press letter for action{/yellow-fg}';
    }

    // Generate status content
    getStatusContent() {
        return '\n  {bold}Controls:{/bold} {cyan-fg}TAB{/cyan-fg}: Focus │ {cyan-fg}1-6{/cyan-fg}: Desktop │ {cyan-fg}Letters{/cyan-fg}: Tools/Actions\n' +
               '  {red-fg}Q{/red-fg}: Quit │ {yellow-fg}ESC{/yellow-fg}: Bash Fallback │ {blue-fg}F1{/blue-fg}: Help';
    }

    // Bind keyboard events
    bindKeys() {
        // Quit keys
        this.screen.key(['q', 'Q', 'C-c'], () => {
            this.quit();
        });

        // Escape to bash fallback
        this.screen.key(['escape'], () => {
            this.launchBashFallback();
        });

        // Tab to switch focus
        this.screen.key(['tab'], () => {
            this.switchFocus();
        });

        // Desktop environment keys
        this.desktops.forEach(desktop => {
            this.screen.key([desktop.id], () => {
                this.launchDesktop(desktop);
            });
        });

        // CLI tool keys
        this.tools.forEach(tool => {
            this.screen.key([tool.key, tool.key.toUpperCase()], () => {
                this.launchTool(tool);
            });
        });

        // System action keys
        this.screen.key(['r', 'R'], () => this.launchAction('recovery'));
        this.screen.key(['s', 'S'], () => this.launchAction('status'));
        this.screen.key(['t', 'T'], () => this.launchAction('telegram'));
        this.screen.key(['f', 'F'], () => this.launchAction('fast'));
        this.screen.key(['b', 'B'], () => this.launchAction('bash'));
        this.screen.key(['i', 'I'], () => this.launchAction('info'));

        // Help key
        this.screen.key(['f1'], () => {
            this.showHelp();
        });
    }

    // Switch focus between sections
    switchFocus() {
        const focuses = ['desktops', 'tools', 'actions'];
        const currentIndex = focuses.indexOf(this.currentFocus);
        this.currentFocus = focuses[(currentIndex + 1) % focuses.length];
        
        // Update border colors
        this.desktopBox.style.border.fg = this.currentFocus === 'desktops' ? 'yellow' : 'gray';
        this.toolsBox.style.border.fg = this.currentFocus === 'tools' ? 'yellow' : 'gray';
        this.actionsBox.style.border.fg = this.currentFocus === 'actions' ? 'yellow' : 'gray';
        
        // Update content to show focus highlights
        this.desktopBox.setContent(this.getDesktopContent());
        this.toolsBox.setContent(this.getToolsContent());
        this.actionsBox.setContent(this.getActionsContent());
        
        this.screen.render();
    }

    // Launch desktop environment
    launchDesktop(desktop) {
        this.screen.destroy();
        console.log(`\nLaunching ${desktop.name}...`);
        
        // Set environment variables
        if (desktop.name.includes('Wayland') || desktop.name.includes('Sway') || desktop.name.includes('Hyprland') || desktop.name.includes('COSMIC')) {
            process.env.XDG_SESSION_TYPE = 'wayland';
            if (desktop.name.includes('KDE')) {
                process.env.QT_QPA_PLATFORM = 'wayland';
            }
        } else {
            process.env.XDG_SESSION_TYPE = 'x11';
        }
        
        try {
            execSync(desktop.cmd, { stdio: 'inherit' });
        } catch (error) {
            console.error(`Failed to launch ${desktop.name}: ${error.message}`);
            process.exit(1);
        }
    }

    // Launch CLI tool
    launchTool(tool) {
        this.screen.destroy();
        console.log(`\nLaunching ${tool.name}...`);
        
        try {
            execSync(tool.cmd, { stdio: 'inherit' });
        } catch (error) {
            console.error(`Failed to launch ${tool.name}: ${error.message}`);
        }
        
        // Return to session manager after tool exits
        console.log('\nPress Enter to return to session manager...');
        process.stdin.setRawMode(false);
        process.stdin.resume();
        process.stdin.once('data', () => {
            this.restart();
        });
    }

    // Launch system action
    launchAction(action) {
        this.screen.destroy();
        
        const actions = {
            recovery: () => {
                console.log('\nLaunching Recovery Wizard...');
                execSync(`bash ${this.dotfilesDir}/scripts/post-install/recovery-wizard.sh`, { stdio: 'inherit' });
            },
            status: () => {
                console.log('\nSystem Status:');
                execSync('uname -a', { stdio: 'inherit' });
                execSync('uptime', { stdio: 'inherit' });
                execSync('free -h', { stdio: 'inherit' });
                execSync('df -h /', { stdio: 'inherit' });
            },
            telegram: () => {
                console.log('\nTelegram Setup...');
                execSync(`bash ${this.dotfilesDir}/scripts/utils/telegram/tele.sh --setup`, { stdio: 'inherit' });
            },
            fast: () => {
                console.log('\nSwitching to fast mode...');
                execSync(`bash ${this.dotfilesDir}/scripts/session-manager-fast`, { stdio: 'inherit' });
            },
            bash: () => {
                this.launchBashFallback();
            },
            info: () => {
                console.log('\nDetailed System Information:');
                if (this.commandExists('neofetch')) {
                    execSync('neofetch', { stdio: 'inherit' });
                } else {
                    execSync('lscpu | head -10', { stdio: 'inherit' });
                }
            }
        };

        if (actions[action]) {
            try {
                actions[action]();
                
                if (action !== 'fast' && action !== 'bash') {
                    console.log('\nPress Enter to return to session manager...');
                    process.stdin.setRawMode(false);
                    process.stdin.resume();
                    process.stdin.once('data', () => {
                        this.restart();
                    });
                }
            } catch (error) {
                console.error(`Action failed: ${error.message}`);
                this.restart();
            }
        }
    }

    // Launch bash fallback
    launchBashFallback() {
        this.screen.destroy();
        console.log('\nSwitching to bash session manager...');
        try {
            execSync(`bash ${this.dotfilesDir}/scripts/session-manager-modular`, { stdio: 'inherit' });
        } catch (error) {
            console.error('Bash fallback failed, dropping to shell');
            process.exit(0);
        }
    }

    // Show help dialog
    showHelp() {
        const helpBox = blessed.message({
            parent: this.screen,
            top: 'center',
            left: 'center',
            width: '80%',
            height: '60%',
            label: ' Help ',
            content: this.getHelpContent(),
            border: {
                type: 'line'
            },
            style: {
                fg: 'white',
                bg: 'blue',
                border: {
                    fg: 'yellow'
                }
            }
        });

        helpBox.focus();
        this.screen.render();

        helpBox.key(['escape', 'q', 'enter'], () => {
            helpBox.destroy();
            this.screen.render();
        });
    }

    // Generate help content
    getHelpContent() {
        return '{center}{bold}═══════════════════════════════════════════════════════════════════{/bold}{/center}\n' +
               '{center}{bold}║                    TTY SESSION MANAGER HELP                      ║{/bold}{/center}\n' +
               '{center}{bold}═══════════════════════════════════════════════════════════════════{/bold}{/center}\n\n' +
               '{bold}Navigation:{/bold}\n' +
               '  {cyan-fg}TAB{/cyan-fg}             - Switch between sections (Desktop/Tools/Actions)\n' +
               '  {green-fg}Numbers 1-6{/green-fg}    - Launch desktop environments\n' +
               '  {yellow-fg}Letters{/yellow-fg}        - Launch CLI tools (c,t,b,r,v)\n' +
               '  {magenta-fg}CAPITAL Letters{/magenta-fg} - System actions (R,S,T,F,B,I)\n\n' +
               '{bold}Special Keys:{/bold}\n' +
               '  {red-fg}Q / Ctrl+C{/red-fg}      - Quit to shell\n' +
               '  {yellow-fg}ESC{/yellow-fg}             - Bash fallback mode (modular session manager)\n' +
               '  {blue-fg}F1{/blue-fg}              - This help dialog\n\n' +
               '{bold}Features:{/bold}\n' +
               '  • Auto-detection of installed desktop environments\n' +
               '  • CLI tools integration with return-to-menu\n' +
               '  • Post-reinstall recovery wizard\n' +
               '  • Telegram integration setup\n' +
               '  • Visual focus indicators with TAB navigation\n\n' +
               '{center}{gray-fg}This is a blessed.js TUI interface for session management{/gray-fg}{/center}\n' +
               '{center}{gray-fg}Fallback bash version available via ESC key{/gray-fg}{/center}\n\n' +
               '{center}{yellow-fg}Press ESC, Q, or ENTER to close this help{/yellow-fg}{/center}';
    }

    // Restart the interface
    restart() {
        process.stdin.setRawMode(true);
        const newManager = new SessionManagerTUI();
    }

    // Clean quit
    quit() {
        this.screen.destroy();
        console.log('\nGoodbye from TUI Session Manager!');
        process.exit(0);
    }
}

// Handle process signals
process.on('SIGTERM', () => process.exit(0));
process.on('SIGINT', () => process.exit(0));

// Start the TUI
const manager = new SessionManagerTUI();