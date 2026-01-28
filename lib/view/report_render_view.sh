#!/bin/bash

# ==============================================================================
# Layer: View
# File: report_render_view.sh
# Responsibility: Decoupling AI content from presentation via static templates.
# ==============================================================================

view_render_audit_report() {
    local json_findings="$1"
    local format="$2"
    local output_file="$3"
    
    local template_file="$SCRIPT_DIR/lib/view/templates/audit_report.$format"
    if [ ! -f "$template_file" ]; then
        echo "Error: Template not found for format $format"
        return 1
    fi
    
    case "$format" in
        html) _view_render_audit_html "$json_findings" "$template_file" > "$output_file" ;;
        md)   _view_render_audit_md   "$json_findings" "$template_file" > "$output_file" ;;
        txt)  _view_render_audit_txt  "$json_findings" "$template_file" > "$output_file" ;;
    esac
}

_view_render_audit_html() {
    local data="$1"
    local template=$(cat "$2")
    
    local verdict=$(echo "$data" | jq -r '.audit_summary.verdict')
    local summary=$(echo "$data" | jq -r '.audit_summary.rationale')
    
    # Tables
    local t_cluster="<table><tr><th>K8s Version</th><th>Arch</th><th>CRI</th><th>Helm</th><th>CNI</th></tr>"
    t_cluster+="<tr><td>$(echo "$data" | jq -r '.evaluation.cluster_info.k8s_version')</td>"
    t_cluster+="<td>$(echo "$data" | jq -r '.evaluation.cluster_info.architecture')</td>"
    t_cluster+="<td>$(echo "$data" | jq -r '.evaluation.cluster_info.cri_runtime')</td>"
    t_cluster+="<td>$(echo "$data" | jq -r '.evaluation.cluster_info.helm_version')</td>"
    t_cluster+="<td>$(echo "$data" | jq -r '.evaluation.cluster_info.cni_plugin')</td></tr></table>"
    
    local t_res="<table><tr><th>Resource</th><th>Available</th><th>Required</th><th>Status</th></tr>"
    t_res+="<tr><td>CPU Cores</td><td>$(echo "$data" | jq -r '.evaluation.resources.cpu_cores.available')</td><td>12</td><td>$(echo "$data" | jq -r '.evaluation.resources.cpu_cores.status')</td></tr>"
    t_res+="<tr><td>RAM (GiB)</td><td>$(echo "$data" | jq -r '.evaluation.resources.ram_gib.available')</td><td>20</td><td>$(echo "$data" | jq -r '.evaluation.resources.ram_gib.status')</td></tr>"
    t_res+="<tr><td>Disk (GiB)</td><td>$(echo "$data" | jq -r '.evaluation.resources.disk_gib.available')</td><td>40</td><td>$(echo "$data" | jq -r '.evaluation.resources.disk_gib.status')</td></tr></table>"
    
    local t_nodes="<table><tr><th>Node Name</th><th>Role</th><th>Kernel</th><th>eBPF</th><th>Headers</th></tr>"
    while read -r row; do
        t_nodes+="<tr><td>$(echo "$row" | jq -r '.name')</td><td>$(echo "$row" | jq -r '.role')</td><td>$(echo "$row" | jq -r '.kernel')</td><td>$(echo "$row" | jq -r '.ebpf_status')</td><td>$(echo "$row" | jq -r '.headers_status')</td></tr>"
    done < <(echo "$data" | jq -c '.evaluation.nodes[]')
    t_nodes+="</table>"
    
    local t_infra="<table><tr><th>Component</th><th>Status</th><th>Notes</th></tr>"
    while read -r row; do
        t_infra+="<tr><td>$(echo "$row" | jq -r '.name')</td><td>$(echo "$row" | jq -r '.status')</td><td>$(echo "$row" | jq -r '.notes')</td></tr>"
    done < <(echo "$data" | jq -c '.evaluation.infrastructure[]')
    t_infra+="</table>"
    
    # Lists
    local l_gaps=""
    while read -r row; do
        l_gaps+="<li class=\"$(echo "$row" | jq -r '.impact')\"><strong>$(echo "$row" | jq -r '.impact')</strong>: $(echo "$row" | jq -r '.description')</li>"
    done < <(echo "$data" | jq -c '.critical_gaps[]')
    
    local l_remed=""
    while read -r row; do
        l_remed+="<div class=\"remediation-box\"><h3>$(echo "$row" | jq -r '.title')</h3><p>$(echo "$row" | jq -r '.description')</p><code>$(echo "$row" | jq -r '.command')</code></div>"
    done < <(echo "$data" | jq -c '.remediation[]')
    
    # Inject
    local rendered="${template//\[\[VERDICT\]\]/$verdict}"
    rendered="${rendered//\[\[SUMMARY\]\]/$summary}"
    rendered="${rendered//\[\[TABLE_CLUSTER\]\]/$t_cluster}"
    rendered="${rendered//\[\[TABLE_RESOURCES\]\]/$t_res}"
    rendered="${rendered//\[\[TABLE_NODES\]\]/$t_nodes}"
    rendered="${rendered//\[\[TABLE_INFRA\]\]/$t_infra}"
    rendered="${rendered//\[\[LIST_GAPS\]\]/$l_gaps}"
    rendered="${rendered//\[\[REMEDIATION_PLAN\]\]/$l_remed}"
    
    echo "$rendered"
}

_view_render_audit_md() {
    local data="$1"
    local template=$(cat "$2")
    
    local verdict=$(echo "$data" | jq -r '.audit_summary.verdict')
    local summary=$(echo "$data" | jq -r '.audit_summary.rationale')
    
    local t_cluster="| K8s Version | Arch | CRI | Helm | CNI |\n|---|---|---|---|---|\n| $(echo "$data" | jq -r '.evaluation.cluster_info.k8s_version') | $(echo "$data" | jq -r '.evaluation.cluster_info.architecture') | $(echo "$data" | jq -r '.evaluation.cluster_info.cri_runtime') | $(echo "$data" | jq -r '.evaluation.cluster_info.helm_version') | $(echo "$data" | jq -r '.evaluation.cluster_info.cni_plugin') |"
    
    local t_res="| Resource | Available | Required | Status |\n|---|---|---|---|\n| CPU Cores | $(echo "$data" | jq -r '.evaluation.resources.cpu_cores.available') | 12 | $(echo "$data" | jq -r '.evaluation.resources.cpu_cores.status') |\n| RAM (GiB) | $(echo "$data" | jq -r '.evaluation.resources.ram_gib.available') | 20 | $(echo "$data" | jq -r '.evaluation.resources.ram_gib.status') |\n| Disk (GiB) | $(echo "$data" | jq -r '.evaluation.resources.disk_gib.available') | 40 | $(echo "$data" | jq -r '.evaluation.resources.disk_gib.status') |"
    
    local t_nodes="| Node Name | Role | Kernel | eBPF | Headers |\n|---|---|---|---|---|"
    while read -r row; do
        t_nodes+="\n| $(echo "$row" | jq -r '.name') | $(echo "$row" | jq -r '.role') | $(echo "$row" | jq -r '.kernel') | $(echo "$row" | jq -r '.ebpf_status') | $(echo "$row" | jq -r '.headers_status') |"
    done < <(echo "$data" | jq -c '.evaluation.nodes[]')
    
    local t_infra="| Component | Status | Notes |\n|---|---|---|"
    while read -r row; do
        t_infra+="\n| $(echo "$row" | jq -r '.name') | $(echo "$row" | jq -r '.status') | $(echo "$row" | jq -r '.notes') |"
    done < <(echo "$data" | jq -c '.evaluation.infrastructure[]')
    
    local l_gaps=""
    while read -r row; do
        l_gaps+="- **$(echo "$row" | jq -r '.impact')**: $(echo "$row" | jq -r '.description')\n"
    done < <(echo "$data" | jq -c '.critical_gaps[]')
    
    local l_remed=""
    while read -r row; do
        l_remed+="### $(echo "$row" | jq -r '.title')\n$(echo "$row" | jq -r '.description')\n\`\`\`bash\n$(echo "$row" | jq -r '.command')\n\`\`\`\n\n"
    done < <(echo "$data" | jq -c '.remediation[]')
    
    local rendered="${template//\[\[VERDICT\]\]/$verdict}"
    rendered="${rendered//\[\[SUMMARY\]\]/$summary}"
    rendered="${rendered//\[\[TABLE_CLUSTER\]\]/$t_cluster}"
    rendered="${rendered//\[\[TABLE_RESOURCES\]\]/$t_res}"
    rendered="${rendered//\[\[TABLE_NODES\]\]/$t_nodes}"
    rendered="${rendered//\[\[TABLE_INFRA\]\]/$t_infra}"
    rendered="${rendered//\[\[LIST_GAPS\]\]/$l_gaps}"
    rendered="${rendered//\[\[REMEDIATION_PLAN\]\]/$l_remed}"
    
    echo -e "$rendered"
}

_view_render_audit_txt() {
    local data="$1"
    local template=$(cat "$2")
    
    local verdict=$(echo "$data" | jq -r '.audit_summary.verdict')
    local summary=$(echo "$data" | jq -r '.audit_summary.rationale')
    
    local t_cluster="K8s: $(echo "$data" | jq -r '.evaluation.cluster_info.k8s_version') | Arch: $(echo "$data" | jq -r '.evaluation.cluster_info.architecture') | CRI: $(echo "$data" | jq -r '.evaluation.cluster_info.cri_runtime')"
    
    local t_res="CPU: $(echo "$data" | jq -r '.evaluation.resources.cpu_cores.available')/12\nRAM: $(echo "$data" | jq -r '.evaluation.resources.ram_gib.available')/20\nDisk: $(echo "$data" | jq -r '.evaluation.resources.disk_gib.available')/40"
    
    local t_nodes=""
    while read -r row; do
        t_nodes+="* $(echo "$row" | jq -r '.name') ($(echo "$row" | jq -r '.role')): Kernel $(echo "$row" | jq -r '.kernel') | eBPF: $(echo "$row" | jq -r '.ebpf_status')\n"
    done < <(echo "$data" | jq -c '.evaluation.nodes[]')
    
    local t_infra=""
    while read -r row; do
        t_infra+="* $(echo "$row" | jq -r '.name'): $(echo "$row" | jq -r '.status') ($(echo "$row" | jq -r '.notes'))\n"
    done < <(echo "$data" | jq -c '.evaluation.infrastructure[]')
    
    local l_gaps=""
    while read -r row; do
        l_gaps+="[$(echo "$row" | jq -r '.impact')] $(echo "$row" | jq -r '.description')\n"
    done < <(echo "$data" | jq -c '.critical_gaps[]')
    
    local l_remed=""
    while read -r row; do
        l_remed+=":: $(echo "$row" | jq -r '.title') ::\n$(echo "$row" | jq -r '.description')\nCMD: $(echo "$row" | jq -r '.command')\n\n"
    done < <(echo "$data" | jq -c '.remediation[]')
    
    local rendered="${template//\[\[VERDICT\]\]/$verdict}"
    rendered="${rendered//\[\[SUMMARY\]\]/$summary}"
    rendered="${rendered//\[\[TABLE_CLUSTER\]\]/$t_cluster}"
    rendered="${rendered//\[\[TABLE_RESOURCES\]\]/$t_res}"
    rendered="${rendered//\[\[TABLE_NODES\]\]/$t_nodes}"
    rendered="${rendered//\[\[TABLE_INFRA\]\]/$t_infra}"
    rendered="${rendered//\[\[LIST_GAPS\]\]/$l_gaps}"
    rendered="${rendered//\[\[REMEDIATION_PLAN\]\]/$l_remed}"
    
    echo -e "$rendered"
}

view_render_report_dashboard() {
    local index_json="$1"
    local version="$2"
    
    cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kaspersky Container Security – Report Hub</title>
    <style>
        :root {
            --primary: #006d5b;
            --primary-hover: #004d40;
            --bg: #f4f7f6;
            --text: #2c3e50;
            --accent: #ff5a00;
            --white: #ffffff;
            --shadow: 0 4px 20px rgba(0,0,0,0.08);
        }
        body { font-family: 'Segoe UI', system-ui, -apple-system, sans-serif; background-color: var(--bg); color: var(--text); margin: 0; padding: 40px 20px; line-height: 1.6; }
        .container { max-width: 1200px; margin: 0 auto; background: var(--white); padding: 40px; border-radius: 12px; box-shadow: var(--shadow); }
        .header { display: flex; align-items: center; justify-content: space-between; border-bottom: 2px solid #eee; padding-bottom: 20px; margin-bottom: 40px; }
        .header h1 { margin: 0; color: var(--primary); font-size: 2rem; }
        .header .badge { background: var(--primary); color: white; padding: 5px 15px; border-radius: 20px; font-size: 0.8rem; font-weight: bold; }
        
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { text-align: left; background: #f8fafc; padding: 15px; border-bottom: 2px solid #edf2f7; color: #4a5568; font-size: 0.85rem; text-transform: uppercase; letter-spacing: 1px; }
        td { padding: 15px; border-bottom: 1px solid #edf2f7; font-size: 0.95rem; }
        tr:hover { background-color: #f7fafc; }
        
        .hash { font-family: 'Courier New', monospace; font-weight: bold; color: var(--primary); }
        .type-ai { color: #805ad5; font-weight: bold; }
        .type-template { color: #718096; }
        
        .btn { display: inline-block; padding: 8px 16px; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.85rem; transition: background 0.2s; }
        .btn-view { background: var(--primary); color: white; }
        .btn-view:hover { background: var(--primary-hover); }
        
        .empty { text-align: center; padding: 60px; color: #a0aec0; }
        .footer { margin-top: 40px; text-align: center; font-size: 0.85rem; color: #a0aec0; border-top: 1px solid #eee; padding-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>KCSPOC Report Hub</h1>
                <p>Diagnostic and Operational Insights</p>
            </div>
            <span class="badge">V${version}</span>
        </div>
        
        <table>
            <thead>
                <tr>
                    <th>Date</th>
                    <th>ID</th>
                    <th>Command</th>
                    <th>Format</th>
                    <th>Type</th>
                    <th>AI Model</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
EOF

    if [ "$(echo "$index_json" | jq 'length')" -eq 0 ]; then
        echo "<tr><td colspan='7' class='empty'>No reports found. Generate one with <code>kcspoc check --report</code></td></tr>"
    else
        echo "$index_json" | jq -r -c 'reverse | .[]' | while read -r row; do
            local h=$(echo "$row" | jq -r '.hash')
            local c=$(echo "$row" | jq -r '.command')
            local t=$(echo "$row" | jq -r '.timestamp')
            local e=$(echo "$row" | jq -r '.extension')
            local tp=$(echo "$row" | jq -r '.type // "template"')
            local m=$(echo "$row" | jq -r '.ai_model // "-"')
            
            # Formatting Date
            local d=$(date -d "$t" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "$t")
            
            # Link creation
            local link="${c}/${h}.${e}"
            
            echo "<tr>"
            echo "  <td>$d</td>"
            echo "  <td><span class='hash'>$h</span></td>"
            echo "  <td><strong>$c</strong></td>"
            echo "  <td>$e</td>"
            echo "  <td class='type-$tp'>$tp</td>"
            echo "  <td>$m</td>"
            echo "  <td><a href='$link' class='btn btn-view' target='_blank'>View Report</a></td>"
            echo "</tr>"
        done
    fi

    cat <<EOF
            </tbody>
        </table>
        
        <div class="footer">
            Generated by <strong>Antigravity Engine</strong> for Kaspersky Container Security PoC Tool
        </div>
    </div>
</body>
</html>
EOF
}
