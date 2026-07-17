<!DOCTYPE html>
<html>
<head>
<title>ASUSWRT</title>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<style>
    .status-ok { color: #5cb85c; font-weight: bold; }
    .status-err { color: #d9534f; font-weight: bold; }
    textarea.custom-opt { width: 98%; height: 150px; font-family: Consolas, monospace; background: #1a2224; color: #00ff00; border: 1px solid #666; padding: 5px; }
</style>
<script>
function initial() {
    show_menu();
    document.form.current_page.value = window.location.pathname.split('/').pop();
    pollMetrics();
}
</script>
</head>
<body onload="initial();" onunLoad="return unload_body();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" width="0" height="0" frameborder="0" scrolling="no" style="display:none;"></iframe>
<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="group_id" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_wait" value="">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">

<table class="content" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td width="17">&nbsp;</td>
    <td valign="top" width="202">
      <div id="mainMenu"></div>
      <div id="subMenu"></div>
    </td>
    <td valign="top">
      <div id="tabMenu" class="submenuBlock"></div>
      <table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
        <tr>
          <td valign="top">
            <table width="760px" border="0" cellpadding="4" cellspacing="0" class="FormTitle" id="FormTitle" style="min-height: 600px;">
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

                  <div style="margin:20px 0 10px 5px;" class="splitLine"></div>
                  <div class="formfonttitle">System Logs</div>
                  <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
                      <tr>
                          <td style="padding:0;">
                              <textarea id="metric-log" class="custom-opt" style="width:100%; height:200px; border:none; resize:none;" readonly>Waiting for logs...</textarea>
                          </td>
                      </tr>
                  </table>

              </td>
              </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </table>
    </td>
    <td width="10" align="center" valign="top">&nbsp;</td>
  </tr>
</table>
</form>

<div id="footer"></div>

<script>
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
        
        let safeCustom = data.custom_opt.replace(/\n/g, '@@NL@@').replace(/\r/g, '');
        const str = "enable=" + data.enable + "\n" +
                    "mode=" + data.mode + "\n" +
                    "ports=" + data.ports + "\n" +
                    "custom_opt=" + safeCustom;
        const b64Str = b64urlEncode(str);
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
            $.post('/apply.cgi', {
                action_mode: 'Update',
                action_script: action_script,
                action_wait: '1',
                current_page: document.form.current_page.value
            }).done(function(res) {
                resolve(res);
            }).fail(function(xhr, status, err) {
                reject(err);
            });
        });
    }

    function pollMetrics() {
        sendChunk("z2gui_status").then(() => {
            setTimeout(() => {
                $.getJSON('/user/user3.asp?t=' + Date.now())
                    .done(function(json) {
                        let statusHtml = "";
                        if (json.status === 'running') {
                            statusHtml = '<span class="status-ok">Running (PID: ' + json.pid + ')</span>';
                        } else {
                            statusHtml = '<span class="status-err">Stopped</span>';
                        }
                        document.getElementById('metric-status').innerHTML = statusHtml;
                        document.getElementById('metric-cpu').innerText = json.cpu_ram || 'N/A';
                        document.getElementById('metric-iptables').innerText = json.iptables_count + ' active hooks';
                        
                        if (json.log) {
                            const logEl = document.getElementById('metric-log');
                            const isScrolledToBottom = logEl.scrollHeight - logEl.clientHeight <= logEl.scrollTop + 1;
                            logEl.value = json.log;
                            if (isScrolledToBottom) {
                                logEl.scrollTop = logEl.scrollHeight;
                            }
                        }
                    })
                    .always(function() {
                        setTimeout(pollMetrics, 5000);
                    });
            }, 1500);
        }).catch(() => {
            setTimeout(pollMetrics, 5000);
        });
    }

</script>
</body>
</html>
