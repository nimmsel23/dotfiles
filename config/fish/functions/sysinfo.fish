function sysinfo --description "Quick system information"
    echo "💻 System Information"
    echo "══════════════════════════════════"
    echo ""

    # OS Info
    echo "🐧 OS: "(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
    echo "🔧 Kernel: "(uname -r)
    echo "🖥️  Hostname: "(hostname)

    echo ""

    # Hardware
    echo "🧠 CPU: "(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    echo "💾 RAM: "(free -h | awk '/^Mem:/ {print $3 " / " $2 " used"}')

    echo ""

    # Disk Usage
    echo "📀 Disk Usage:"
    df -h / | awk 'NR==2 {print "   Root: " $3 " / " $2 " used (" $5 ")"}'
    if test -d ~/AlphaOs-Vault
        du -sh ~/AlphaOs-Vault | awk '{print "   AlphaOs-Vault: " $1}'
    end

    echo ""

    # Uptime
    echo "⏱️  Uptime: "(uptime -p)

    echo ""

    # Network
    echo "🌐 Network:"
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | while read ip
        echo "   IP: $ip"
    end
end
