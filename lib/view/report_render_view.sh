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
