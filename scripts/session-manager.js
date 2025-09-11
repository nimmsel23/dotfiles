#!/usr/bin/env node

/**
 * 🌈 Session Manager JavaScript Edition 🚀
 * Ultra-modern Node.js interface for desktop session management
 */

const { execSync, exec } = require('child_process');
const readline = require('readline');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
    version: '5.0-JS',
    dotfilesDir: process.env.HOME + '/.dotfiles',
    theme: {
        primary: '🌈',
        secondary: '✨',
        success: '🟢',
        warning: '🟡',
        error: '🔴',
        desktop: '🏠',
        tool: '🛠️',
        api: '⚡'
    }
};

class SessionManager {
    constructor() {
        this.rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
    }

    // Utility functions
    log(message, emoji = '📘') {
        const timestamp = new Date().toLocaleTimeString();
        console.log(`${emoji} [${timestamp}] ${message}`);
    }

    success(message) { this.log(message, '✅'); }
    error(message) { this.log(message, '❌'); }
    warning(message) { this.log(message, '⚠️'); }

    // Check if command exists
    commandExists(cmd) {
        try {
            execSync(`command -v ${cmd}`, { stdio: 'ignore' });
            return true;
        } catch {
            return false;
        }
    }

    // Detect available desktop environments
    detectDesktops() {
        const desktops = [];
        
        if (this.commandExists('startplasma-wayland')) {
            desktops.push({ id: 1, name: 'KDE Plasma (Wayland)', cmd: 'startplasma-wayland', wayland: true });
        }
        
        if (this.commandExists('sway')) {
            desktops.push({ id: 2, name: 'Sway', cmd: 'sway', wayland: true });
        }
        
        if (this.commandExists('Hyprland')) {
            desktops.push({ id: 3, name: 'Hyprland', cmd: 'Hyprland', wayland: true });
        }
        
        if (this.commandExists('cosmic-session')) {
            desktops.push({ id: 4, name: 'COSMIC Desktop', cmd: 'cosmic-session', wayland: true });
        }
        
        if (this.commandExists('startxfce4')) {
            desktops.push({ id: 5, name: 'XFCE', cmd: 'startx /usr/bin/startxfce4', wayland: false });
        }
        
        if (this.commandExists('i3')) {
            desktops.push({ id: 6, name: 'i3 (X11)', cmd: 'startx /usr/bin/i3', wayland: false });
        }
        
        return desktops;
    }

    // Detect available CLI tools
    detectTools() {
        const tools = [];
        
        if (this.commandExists('calcurse')) {
            tools.push({ key: 'c', name: 'Calendar (calcurse)', cmd: 'calcurse' });
        }
        
        if (this.commandExists('taskwarrior-tui')) {
            tools.push({ key: 't', name: 'Tasks (taskwarrior-tui)', cmd: 'taskwarrior-tui' });
        }
        
        if (this.commandExists('btop')) {
            tools.push({ key: 'b', name: 'System Monitor (btop)', cmd: 'btop' });
        }
        
        if (this.commandExists('ranger')) {
            tools.push({ key: 'r', name: 'File Manager (ranger)', cmd: 'ranger' });
        }
        
        if (this.commandExists('nvim')) {
            tools.push({ key: 'v', name: 'Neovim Editor', cmd: 'nvim' });
        }
        
        return tools;
    }

    // Get system information
    async getSystemInfo() {
        try {
            const hostname = execSync('hostname').toString().trim();
            const uptime = execSync("uptime -p").toString().trim();
            const load = execSync("uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'").toString().trim();
            const memUsage = execSync("free | awk '/^Mem:/ {printf \"%.1f\", $3/$2 * 100.0}'").toString().trim();
            
            return {
                hostname,
                uptime,
                loadAverage: parseFloat(load) || 0,
                memoryUsage: parseFloat(memUsage) || 0,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                hostname: 'unknown',
                uptime: 'unknown',
                loadAverage: 0,
                memoryUsage: 0,
                timestamp: new Date().toISOString()
            };
        }
    }

    // Display fancy header
    async showHeader() {
        const sysInfo = await this.getSystemInfo();
        
        console.clear();
        console.log('╔════════════════════════════════════════════════════════════════╗');
        console.log(`║  ${CONFIG.theme.primary} JavaScript Session Manager v${CONFIG.version} ${CONFIG.theme.secondary}  ║`);
        console.log('╠════════════════════════════════════════════════════════════════╣');
        console.log(`║ ${sysInfo.hostname} | ${sysInfo.uptime} | Load: ${sysInfo.loadAverage} | RAM: ${sysInfo.memoryUsage}% ║`);
        console.log('╚════════════════════════════════════════════════════════════════╝');
        console.log();
    }

    // Show main menu
    async showMenu() {
        await this.showHeader();
        
        const desktops = this.detectDesktops();
        const tools = this.detectTools();
        
        // Desktop Environments
        if (desktops.length > 0) {
            console.log(`${CONFIG.theme.desktop} Desktop Environments (${desktops.length} available):`);
            console.log('┌─────────────────────────────────────────────────────────────────┐');
            desktops.forEach(de => {
                const waylandIcon = de.wayland ? '🌊' : '🖥️';
                console.log(`│  [${de.id}] ${de.name} ${waylandIcon}`);
            });
            console.log('└─────────────────────────────────────────────────────────────────┘');
            console.log();
        }
        
        // CLI Tools
        if (tools.length > 0) {
            console.log(`${CONFIG.theme.tool} Quick CLI Tools (${tools.length} available):`);
            console.log('┌─────────────────────────────────────────────────────────────────┐');
            tools.forEach(tool => {
                console.log(`│  [${tool.key}] ${tool.name}`);
            });
            console.log('└─────────────────────────────────────────────────────────────────┘');
            console.log();
        }
        
        // JavaScript Features
        console.log(`${CONFIG.theme.api} JavaScript Features:`);
        console.log('  [api] 🔥 Live System API');
        console.log('  [web] 🌐 Web Interface');
        console.log('  [bench] 🚀 Performance Benchmark');
        console.log('  [watch] 👁️ Live System Monitor');
        console.log();
        
        // Telegram Features
        console.log('📱 Telegram Integration:');
        console.log('  [tele] 💬 Send Telegram Message');
        console.log('  [tele-setup] 🔧 Configure Telegram');
        console.log('  [tele-service] 🤖 Telegram Service Control');
        console.log();
        
        // System Options
        console.log('⚙️ System Options:');
        console.log('  [bash] Switch to bash session-manager');
        console.log('  [fast] Switch to ultra-fast launcher');
        console.log();
        
        console.log('┌─────────────────────────────────────────────────────────────────┐');
        console.log('│  [q] ← Exit to bash    [0] Logout    [?] Help                   │');
        console.log('└─────────────────────────────────────────────────────────────────┘');
        console.log();
        
        console.log('💡 Node.js powered session manager with live APIs!');
    }

    // Launch desktop environment
    launchDesktop(id) {
        const desktops = this.detectDesktops();
        const desktop = desktops.find(de => de.id === parseInt(id));
        
        if (!desktop) {
            this.error(`Desktop environment ${id} not found`);
            return false;
        }
        
        this.success(`Launching ${desktop.name}...`);
        
        // Set environment variables
        if (desktop.wayland) {
            process.env.XDG_SESSION_TYPE = 'wayland';
            if (desktop.name.includes('KDE')) {
                process.env.QT_QPA_PLATFORM = 'wayland';
            }
        } else {
            process.env.XDG_SESSION_TYPE = 'x11';
        }
        
        // Launch desktop
        try {
            execSync(desktop.cmd, { stdio: 'inherit' });
        } catch (error) {
            this.error(`Failed to launch ${desktop.name}: ${error.message}`);
        }
        
        return true;
    }

    // Launch CLI tool
    launchTool(key) {
        const tools = this.detectTools();
        const tool = tools.find(t => t.key === key);
        
        if (!tool) {
            this.error(`Tool '${key}' not found`);
            return false;
        }
        
        this.success(`Starting ${tool.name}...`);
        console.clear();
        
        try {
            execSync(tool.cmd, { stdio: 'inherit' });
        } catch (error) {
            this.error(`Failed to launch ${tool.name}: ${error.message}`);
        }
        
        return true;
    }

    // Live system API
    async liveSystemAPI() {
        console.log('🔥 LIVE SYSTEM API - JavaScript Edition');
        console.log('─────────────────────────────────────────');
        
        const sysInfo = await this.getSystemInfo();
        const desktops = this.detectDesktops();
        const tools = this.detectTools();
        
        const apiData = {
            meta: {
                version: CONFIG.version,
                timestamp: sysInfo.timestamp,
                runtime: 'Node.js ' + process.version
            },
            system: sysInfo,
            desktops: desktops,
            tools: tools,
            environment: {
                shell: process.env.SHELL,
                user: process.env.USER,
                home: process.env.HOME,
                display: process.env.DISPLAY || 'N/A',
                wayland: process.env.WAYLAND_DISPLAY || 'N/A'
            }
        };
        
        console.log(JSON.stringify(apiData, null, 2));
        console.log();
        this.success('Live API data generated!');
    }

    // Performance benchmark
    async performanceBenchmark() {
        console.log('🚀 JAVASCRIPT PERFORMANCE BENCHMARK');
        console.log('─────────────────────────────────────');
        
        const startTime = process.hrtime.bigint();
        
        // CPU test
        this.log('Running CPU benchmark...');
        const cpuStart = process.hrtime.bigint();
        let result = 0;
        for (let i = 0; i < 1000000; i++) {
            result += Math.sqrt(i);
        }
        const cpuEnd = process.hrtime.bigint();
        const cpuTime = Number(cpuEnd - cpuStart) / 1000000; // Convert to milliseconds
        
        // Memory test
        this.log('Running memory benchmark...');
        const memStart = process.hrtime.bigint();
        const testArray = [];
        for (let i = 0; i < 100000; i++) {
            testArray.push(`benchmark_string_${i}`);
        }
        const memEnd = process.hrtime.bigint();
        const memTime = Number(memEnd - memStart) / 1000000;
        
        const totalTime = Number(process.hrtime.bigint() - startTime) / 1000000;
        
        const benchmarkResults = {
            timestamp: new Date().toISOString(),
            runtime: 'Node.js ' + process.version,
            platform: process.platform,
            arch: process.arch,
            results: {
                cpu_test: {
                    duration_ms: Math.round(cpuTime),
                    operations: 1000000,
                    rating: cpuTime < 100 ? 'excellent' : cpuTime < 500 ? 'good' : 'needs_improvement'
                },
                memory_test: {
                    duration_ms: Math.round(memTime),
                    operations: 100000,
                    rating: memTime < 50 ? 'excellent' : memTime < 200 ? 'good' : 'needs_improvement'
                }
            },
            total_duration_ms: Math.round(totalTime),
            memory_usage: process.memoryUsage(),
            overall_score: Math.max(0, 100 - Math.round((cpuTime + memTime) / 10))
        };
        
        console.log(JSON.stringify(benchmarkResults, null, 2));
        console.log();
        this.success(`Benchmark complete! Score: ${benchmarkResults.overall_score}/100`);
    }

    // Live system monitor
    async liveSystemMonitor() {
        console.log('👁️ LIVE SYSTEM MONITOR - Press Ctrl+C to exit');
        console.log('─────────────────────────────────────────────────');
        
        const monitor = setInterval(async () => {
            const sysInfo = await this.getSystemInfo();
            const memUsage = process.memoryUsage();
            
            console.clear();
            console.log('👁️ LIVE SYSTEM MONITOR - ' + new Date().toLocaleTimeString());
            console.log('─────────────────────────────────────────────────');
            console.log(`🖥️  Hostname: ${sysInfo.hostname}`);
            console.log(`⏰ Uptime: ${sysInfo.uptime}`);
            console.log(`📊 Load Average: ${sysInfo.loadAverage}`);
            console.log(`🧠 Memory Usage: ${sysInfo.memoryUsage}%`);
            console.log(`⚡ Node.js Memory: ${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`);
            console.log();
            console.log('Press Ctrl+C to exit...');
        }, 2000);
        
        process.on('SIGINT', () => {
            clearInterval(monitor);
            console.log('\n👋 Live monitor stopped');
            this.startInteractiveMode();
        });
    }

    // Handle user input
    async handleChoice(choice) {
        choice = choice.trim().toLowerCase();
        
        // Desktop environments
        if (/^[1-6]$/.test(choice)) {
            this.launchDesktop(choice);
            return;
        }
        
        // CLI tools
        if (['c', 't', 'b', 'r', 'v'].includes(choice)) {
            this.launchTool(choice);
            this.waitForReturn();
            return;
        }
        
        // JavaScript features
        switch (choice) {
            case 'api':
                await this.liveSystemAPI();
                this.waitForReturn();
                break;
                
            case 'bench':
                await this.performanceBenchmark();
                this.waitForReturn();
                break;
                
            case 'watch':
                await this.liveSystemMonitor();
                break;
                
            case 'web':
                this.log('Web interface feature coming soon! 🚧');
                this.waitForReturn();
                break;
                
            // Telegram features
            case 'tele':
                await this.sendTelegramMessage();
                break;
                
            case 'tele-setup':
                await this.setupTelegram();
                break;
                
            case 'tele-service':
                await this.manageTelegramService();
                break;
                
            case 'bash':
                this.success('Switching to bash session-manager...');
                execSync(`${CONFIG.dotfilesDir}/scripts/session-manager-modular`, { stdio: 'inherit' });
                break;
                
            case 'fast':
                this.success('Switching to ultra-fast launcher...');
                execSync(`${CONFIG.dotfilesDir}/scripts/session-manager-fast`, { stdio: 'inherit' });
                break;
                
            case '?':
                this.showHelp();
                this.waitForReturn();
                break;
                
            case 'q':
                this.success('Returning to bash shell...');
                process.exit(0);
                break;
                
            case '0':
                this.success('Goodbye! 👋');
                process.exit(0);
                break;
                
            default:
                this.error(`Invalid choice: '${choice}'`);
                this.waitForReturn();
                break;
        }
    }

    // Send Telegram message interactively
    async sendTelegramMessage() {
        console.log('📱 SEND TELEGRAM MESSAGE');
        console.log('─────────────────────────────');
        
        return new Promise((resolve) => {
            this.rl.question('Enter your message: ', (message) => {
                if (message.trim()) {
                    try {
                        const result = execSync(`bash "${CONFIG.dotfilesDir}/scripts/utils/telegram/tele.sh" "${message}"`, { encoding: 'utf8' });
                        this.success('Message sent via Telegram!');
                        console.log(result);
                    } catch (error) {
                        this.error(`Failed to send message: ${error.message}`);
                    }
                } else {
                    this.warning('No message provided');
                }
                this.waitForReturn();
                resolve();
            });
        });
    }

    // Setup Telegram configuration
    async setupTelegram() {
        console.log('🔧 TELEGRAM SETUP');
        console.log('─────────────────');
        
        try {
            execSync(`bash "${CONFIG.dotfilesDir}/scripts/utils/telegram/tele.sh" --setup`, { stdio: 'inherit' });
            this.success('Telegram setup completed!');
        } catch (error) {
            this.error('Telegram setup failed');
        }
        
        this.waitForReturn();
    }

    // Manage Telegram service
    async manageTelegramService() {
        console.log('🤖 TELEGRAM SERVICE CONTROL');
        console.log('─────────────────────────────');
        console.log('Available commands:');
        console.log('  [1] Start service');
        console.log('  [2] Stop service');
        console.log('  [3] Service status');
        console.log('  [4] Configure service');
        console.log('  [5] Test notifications');
        console.log('  [6] Restart service');
        console.log();
        
        return new Promise((resolve) => {
            this.rl.question('Choose service command: ', (choice) => {
                let command = '';
                
                switch (choice.trim()) {
                    case '1': command = 'start'; break;
                    case '2': command = 'stop'; break;
                    case '3': command = 'status'; break;
                    case '4': command = 'config'; break;
                    case '5': command = 'test'; break;
                    case '6': command = 'restart'; break;
                    default:
                        this.error('Invalid choice');
                        this.waitForReturn();
                        resolve();
                        return;
                }
                
                try {
                    execSync(`bash "${CONFIG.dotfilesDir}/scripts/utils/telegram/tele-service.sh" ${command}`, { stdio: 'inherit' });
                } catch (error) {
                    this.error(`Service command failed: ${error.message}`);
                }
                
                this.waitForReturn();
                resolve();
            });
        });
    }

    // Show help
    showHelp() {
        console.log('🆘 JAVASCRIPT SESSION MANAGER HELP');
        console.log('─────────────────────────────────────');
        console.log('Desktop Environments: 1-6');
        console.log('CLI Tools: c, t, b, r, v');
        console.log('Features: api, bench, watch, web');
        console.log('Telegram: tele, tele-setup, tele-service');
        console.log('System: bash, fast, q, 0');
        console.log();
        console.log('This is a Node.js powered session manager with Telegram integration!');
    }

    // Wait for user to press Enter
    waitForReturn() {
        console.log();
        this.rl.question('Press Enter to continue...', () => {
            this.startInteractiveMode();
        });
    }

    // Start interactive mode
    async startInteractiveMode() {
        await this.showMenu();
        
        this.rl.question('🌈 Choose: ', async (answer) => {
            await this.handleChoice(answer);
        });
    }

    // Main entry point
    async start() {
        // Handle command line arguments
        const args = process.argv.slice(2);
        
        if (args.includes('--help')) {
            console.log('JavaScript Session Manager v' + CONFIG.version);
            console.log('');
            console.log('A modern Node.js powered session manager');
            console.log('');
            console.log('Usage: node session-manager.js [option]');
            console.log('');
            console.log('Options:');
            console.log('  --api       Show live system API');
            console.log('  --bench     Run performance benchmark');
            console.log('  --help      Show this help');
            console.log('');
            console.log('Interactive mode: Run without arguments');
            process.exit(0);
        }
        
        if (args.includes('--api')) {
            await this.liveSystemAPI();
            process.exit(0);
        }
        
        if (args.includes('--bench')) {
            await this.performanceBenchmark();
            process.exit(0);
        }
        
        // Start interactive mode
        this.success('JavaScript Session Manager started!');
        await this.startInteractiveMode();
    }

    // Cleanup
    cleanup() {
        this.rl.close();
    }
}

// Handle process termination
process.on('SIGINT', () => {
    console.log('\n👋 Goodbye from JavaScript Session Manager!');
    process.exit(0);
});

// Start the session manager
const sessionManager = new SessionManager();
sessionManager.start().catch(console.error);