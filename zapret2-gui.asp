<!DOCTYPE html>
<html>
<head>
    <title>Zapret2 GUI</title>
    <meta charset="utf-8">
    <style>
        body { font-family: sans-serif; margin: 20px; background: #2f343f; color: #eee; }
        .container { max-width: 600px; margin: auto; background: #3b4252; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
        h1 { margin-top: 0; color: #88c0d0; }
        .form-group { margin-bottom: 15px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        select, input[type="text"], textarea { width: 100%; padding: 8px; border: 1px solid #4c566a; border-radius: 4px; background: #2e3440; color: #eceff4; box-sizing: border-box; }
        textarea { height: 100px; resize: vertical; }
        button { padding: 10px 15px; background: #81a1c1; border: none; color: #2e3440; font-weight: bold; border-radius: 4px; cursor: pointer; }
        button:hover { background: #88c0d0; }
        .status { margin-bottom: 20px; padding: 10px; border-radius: 4px; background: #434c5e; }
        .status span { font-weight: bold; }
        .status.running span { color: #a3be8c; }
        .status.stopped span { color: #bf616a; }
    </style>
</head>
<body>
<div class="container">
    <h1>Zapret2 Management</h1>
    
    <div id="status-panel" class="status stopped">
        Status: <span id="status-text">Checking...</span>
    </div>

    <div class="form-group">
        <label>Enable Zapret2</label>
        <select id="enable">
            <option value="1">Yes</option>
            <option value="0">No</option>
        </select>
    </div>

    <div class="form-group">
        <label>Strategy Mode</label>
        <select id="mode" onchange="toggleCustom()">
            <option value="fake">Fake</option>
            <option value="multisplit">Multisplit</option>
            <option value="custom">Custom Block</option>
        </select>
    </div>

    <div class="form-group">
        <label>TCP Ports</label>
        <input type="text" id="ports" value="443" placeholder="443,80">
    </div>

    <div class="form-group" id="custom-group" style="display:none;">
        <label>Custom NFQWS2_OPT</label>
        <textarea id="custom_opt" placeholder="--filter-tcp=443 --hostlist=<HOSTLIST> --payload=tls_client_hello --lua-desync=fake --new"></textarea>
    </div>

    <button onclick="applySettings()">Apply Settings</button>
</div>

<!-- Hidden form to trigger AsusWRT rc_service -->
<form method="post" name="hidden_form" id="hidden_form" action="/apply.cgi" style="display:none;">
    <input type="hidden" name="action_mode" value="Update">
    <input type="hidden" name="action_script" value="restart_zapret2gui_apply">
    <input type="hidden" name="action_wait" value="5">
    <input type="hidden" name="current_page" value="zapret2-gui.asp">
</form>

<script>
    function toggleCustom() {
        const mode = document.getElementById('mode').value;
        document.getElementById('custom-group').style.display = mode === 'custom' ? 'block' : 'none';
    }

    function applySettings() {
        const data = {
            enable: document.getElementById('enable').value,
            mode: document.getElementById('mode').value,
            ports: document.getElementById('ports').value,
            custom_opt: document.getElementById('custom_opt').value
        };
        
        const jsonStr = JSON.stringify(data);
        const b64Str = btoa(unescape(encodeURIComponent(jsonStr)));
        
        // As requested: save via fetch to the static file path, then trigger apply.cgi
        fetch('/user/.zapret2gui.apply', {
            method: 'POST',
            body: b64Str
        }).then(() => {
            document.getElementById('hidden_form').submit();
        }).catch(err => {
            alert("Failed to write payload: " + err);
        });
    }

    // In a real Merlin environment, we would use an endpoint to get the status.
    // For now, it's just a mockup visually.
    setTimeout(() => {
        document.getElementById('status-text').innerText = 'Running';
        document.getElementById('status-panel').className = 'status running';
    }, 1000);
</script>
</body>
</html>
