<!DOCTYPE html>
<html>
<head>
    <title>Zapret2 GUI</title>
    <meta charset="utf-8">
    <style>
        /* Minimal fixes, inheriting AsusWRT styles if loaded */
        body { font-family: Arial, Helvetica, sans-serif; background: #222; color: #fff; margin: 0; padding: 0; }
        .FormTitle { background-color: #4D595D; border: 1px solid #6b8fa3; border-radius: 5px; }
        .formfonttitle { font-size: 16px; font-weight: bold; color: #FFFFFF; font-family: Arial, Helvetica, sans-serif; }
        .splitLine { background-color: #6b8fa3; height: 1px; }
        .FormTable { border-collapse: collapse; background-color: #2b373b; border: 1px solid #1c2b30; }
        .FormTable th { background-color: #1f2d35; text-align: left; padding: 5px 8px; font-weight: bold; font-size: 13px; color: #FFFFFF; border: 1px solid #1c2b30; }
        .FormTable td { padding: 5px 8px; font-size: 13px; color: #FFFFFF; border: 1px solid #1c2b30; }
        .input_option { background-color: #1a2224; color: #FFFFFF; border: 1px solid #666; padding: 2px; }
        .input_15_table { background-color: #1a2224; color: #FFFFFF; border: 1px solid #666; padding: 2px; width: 145px; }
        .button_gen { font-weight: bold; color: #FFFFFF; background-color: #3b4245; border: 1px solid #1c2b30; padding: 5px 10px; cursor: pointer; border-radius: 3px; }
        .button_gen:hover { background-color: #4f5a5e; }
        .apply_gen { text-align: center; padding: 15px 0; }
        .status-ok { color: #5cb85c; font-weight: bold; }
        .status-err { color: #d9534f; font-weight: bold; }
        textarea.custom-opt { width: 98%; height: 150px; font-family: Consolas, monospace; background: #1a2224; color: #00ff00; border: 1px solid #666; padding: 5px; }
    </style>
</head>
<body>
<div style="padding: 10px;">
<table width="98%" border="0" align="center" cellpadding="0" cellspacing="0">
<tbody><tr>
<td valign="top">
<table width="760px" border="0" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle" style="min-height: 600px;">
<tbody>
<tr bgcolor="#4D595D">
<td valign="top" style="padding: 15px;">
    <div class="formfonttitle">Zapret2 Management</div>
    <div style="margin:10px 0 10px 5px;" class="splitLine"></div>

    <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
        <tr>
            <th width="30%">Enable Zapret2</th>
            <td>
                <select id="enable" class="input_option">
                    <option value="1">Yes</option>
                    <option value="0">No</option>
                </select>
            </td>
        </tr>
        <tr>
            <th>Strategy Mode</th>
            <td>
                <select id="mode" class="input_option" onchange="toggleCustom()">
                    <option value="fake">Fake (Basic)</option>
                    <option value="multisplit">Multisplit (Advanced)</option>
                    <option value="custom">Custom Windows Script</option>
                </select>
            </td>
        </tr>
        <tr>
            <th>TCP Ports</th>
            <td>
                <input type="text" id="ports" class="input_15_table" value="443" placeholder="443,80">
            </td>
        </tr>
        <tr id="custom-group" style="display:none;">
            <th valign="top">Windows Script Arguments<br><br>
                <small style="font-weight:normal; color:#bbb;">Paste the arguments from your winws.exe batch script here.</small><br><br>
                <small style="font-weight:normal; color:#bbb;">E.g.: --filter-tcp=... --hostlist="%LISTS%list.txt" ^<br>--dpi-desync-fake-tls="%BIN%tls.bin"</small>
            </th>
            <td>
                <textarea id="custom_opt" class="custom-opt"></textarea>
            </td>
        </tr>
    </table>

    <div style="margin:20px 0 10px 5px;" class="splitLine"></div>
    <div class="formfonttitle">System Status</div>
    <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
        <tr>
            <th width="30%">Service Status</th>
            <td id="metric-status">Checking...</td>
        </tr>
        <tr>
            <th>CPU / RAM Usage</th>
            <td id="metric-cpu">Checking...</td>
        </tr>
        <tr>
            <th>Active iptables Hooks</th>
            <td id="metric-iptables">Checking...</td>
        </tr>
    </table>

    <div class="apply_gen">
        <input type="button" id="btnApply" value="Apply Settings" onclick="applySettings();" class="button_gen">
    </div>

</td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>

<form method="post" name="hidden_form" id="hidden_form" action="/apply.cgi" style="display:none;">
    <input type="hidden" name="action_mode" value="Update">
    <input type="hidden" name="action_script" value="">
    <input type="hidden" name="action_wait" value="1">
    <input type="hidden" name="current_page" value="">
</form>

<script>
    document.querySelector('input[name="current_page"]').value = window.location.pathname.split('/').pop();

    function toggleCustom() {
        const mode = document.getElementById('mode').value;
        document.getElementById('custom-group').style.display = mode === 'custom' ? 'table-row' : 'none';
    }

    function b64urlEncode(str) {
        return btoa(unescape(encodeURIComponent(str)))
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '');
    }

    async function applySettings() {
        const data = {
            enable: document.getElementById('enable').value,
            mode: document.getElementById('mode').value,
            ports: document.getElementById('ports').value,
            custom_opt: document.getElementById('custom_opt').value
        };
        
        const jsonStr = JSON.stringify(data);
        const b64Str = b64urlEncode(jsonStr);
        const chunks = b64Str.match(/.{1,100}/g) || [];
        
        const btn = document.getElementById('btnApply');
        btn.value = 'Applying...';
        btn.disabled = true;

        try {
            await sendChunk("z2gui_start");
            for (let i = 0; i < chunks.length; i++) {
                await sendChunk("z2gui_chk_" + chunks[i]);
            }
            await sendChunk("z2gui_apply");
            
            setTimeout(() => {
                btn.value = 'Settings Applied!';
                setTimeout(() => { btn.value = 'Apply Settings'; btn.disabled = false; }, 2000);
            }, 1000);
        } catch (err) {
            alert("Failed to apply settings: " + err);
            btn.value = 'Apply Settings'; 
            btn.disabled = false;
        }
    }

    function sendChunk(action_script) {
        return new Promise((resolve, reject) => {
            const formData = new URLSearchParams();
            formData.append('action_mode', 'Update');
            formData.append('action_script', action_script);
            formData.append('action_wait', '1');
            formData.append('current_page', document.querySelector('input[name="current_page"]').value);

            fetch('/apply.cgi', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: formData.toString()
            }).then(res => resolve(res)).catch(err => reject(err));
        });
    }

    async function pollMetrics() {
        try {
            // Trigger backend to generate metrics JSON
            await sendChunk("z2gui_status");
            
            // Wait 1 second for generation
            setTimeout(async () => {
                try {
                    const res = await fetch('/user/zapret-status.json?t=' + Date.now());
                    if (res.ok) {
                        const json = await res.json();
                        
                        let statusHtml = "";
                        if (json.status === 'running') {
                            statusHtml = `<span class="status-ok">Running (PID: ${json.pid})</span>`;
                        } else {
                            statusHtml = `<span class="status-err">Stopped</span>`;
                        }
                        document.getElementById('metric-status').innerHTML = statusHtml;
                        
                        document.getElementById('metric-cpu').innerText = json.cpu_ram || 'N/A';
                        document.getElementById('metric-iptables').innerText = json.iptables_count + ' active hooks';
                    }
                } catch(e) {}
                
                // Poll every 5 seconds
                setTimeout(pollMetrics, 5000);
            }, 1000);
            
        } catch(e) {
            setTimeout(pollMetrics, 5000);
        }
    }

    // Start polling loop
    pollMetrics();

</script>
</body>
</html>
