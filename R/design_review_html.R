#' @keywords internal
.html_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

#' @keywords internal
.design_review_payload <- function(x, ...) {
  if (inherits(x, "DesignReviewSpec")) {
    return(x$to_list())
  }
  build_design_review_data(x, ...)$to_list()
}

#' Build standalone design-review HTML
#'
#' Creates a standalone, offline HTML/JavaScript review page from a design
#' review bundle or supported design object. The page is review-only: it renders
#' design artifacts and exports structured feedback JSON, but it does not run
#' workflow nodes, call LLM providers, or mutate saved R objects.
#'
#' @param x A [`DesignReviewSpec`] or any input accepted by
#'   [build_design_review_data()].
#' @param include_workflow Whether to render workflow graph information.
#' @param include_knowledge Whether to render narrative and graph knowledge.
#' @param include_memory_schema Whether to render memory/state/interface schema.
#' @param include_feedback_panel Whether to include the structured feedback
#'   form and JSON export controls.
#' @param self_contained Reserved for future asset handling. The current
#'   implementation is always self-contained and uses no remote resources.
#' @param title Optional page title.
#' @param ... Additional arguments passed to [build_design_review_data()] when
#'   `x` is not already a [`DesignReviewSpec`].
#'
#' @return HTML string.
#' @export
design_review_html <- function(
  x,
  include_workflow = TRUE,
  include_knowledge = TRUE,
  include_memory_schema = TRUE,
  include_feedback_panel = TRUE,
  self_contained = TRUE,
  title = NULL,
  ...
) {
  payload <- .design_review_payload(x, ...)
  validate_design_review_spec(payload)
  if (is.null(title)) {
    title <- paste("agentr design review:", payload$agent_name)
  }
  config <- list(
    include_workflow = isTRUE(include_workflow),
    include_knowledge = isTRUE(include_knowledge),
    include_memory_schema = isTRUE(include_memory_schema),
    include_feedback_panel = isTRUE(include_feedback_panel)
  )
  payload_json <- jsonlite::toJSON(payload, auto_unbox = TRUE, null = "null", pretty = FALSE)
  config_json <- jsonlite::toJSON(config, auto_unbox = TRUE, null = "null", pretty = FALSE)

  paste(
    "<!doctype html>",
    '<html lang="en">',
    "<head>",
    '<meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
    paste0("<title>", .html_escape(title), "</title>"),
    "<style>",
    "body{margin:0;background:#f7f5ef;color:#1f2933;font-family:Georgia,'Times New Roman',serif;}",
    "header{padding:28px 34px;border-bottom:1px solid #c8c1b2;background:#efe8d8;}",
    "h1{margin:0 0 8px;font-size:28px;font-weight:600;} h2{font-size:19px;margin:0 0 12px;} h3{font-size:15px;margin:14px 0 6px;}",
    ".meta{font-size:13px;color:#5b6472}.wrap{display:grid;grid-template-columns:minmax(0,1fr) 360px;gap:18px;padding:18px;}",
    ".main{display:grid;gap:18px}.panel{background:#fffdf7;border:1px solid #d7cebd;border-radius:10px;padding:16px;box-shadow:0 1px 2px rgba(0,0,0,.04)}",
    ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:10px}.card{border:1px solid #d8d2c4;border-radius:8px;padding:10px;background:#fff;overflow-wrap:anywhere}",
    ".card button{all:unset;cursor:pointer;display:block;width:100%;overflow-wrap:anywhere}.id{font:12px ui-monospace,SFMono-Regular,Menlo,monospace;color:#6b7280;overflow-wrap:anywhere}.label{font-weight:600;overflow-wrap:anywhere}.small{font-size:12px;color:#52606d;overflow-wrap:anywhere}",
    ".edge{font-size:13px;border-left:3px solid #8aa398;padding:7px 9px;background:#f8fbf8;margin:6px 0}.graph{min-height:170px;border:1px dashed #cfc7b8;border-radius:8px;background:#fbfaf6;margin-bottom:12px}",
    "svg text{font-family:Georgia,'Times New Roman',serif}.feedback{position:sticky;top:12px;align-self:start}.row{display:grid;gap:5px;margin-bottom:9px}",
    "label{font-size:12px;font-weight:600;color:#384252}input,select,textarea{font:13px ui-sans-serif,system-ui,sans-serif;border:1px solid #b9c0c8;border-radius:6px;padding:7px;background:white}",
    "textarea{min-height:62px}.btns{display:flex;gap:8px;flex-wrap:wrap}.btn{border:1px solid #344e41;background:#344e41;color:#fff;border-radius:6px;padding:7px 10px;cursor:pointer;font-size:13px}",
    ".btn.secondary{background:#fff;color:#344e41}.feedback-item{font-size:12px;border:1px solid #d7cebd;border-radius:6px;padding:8px;margin-top:8px;background:#fff}",
    "pre{white-space:pre-wrap;word-break:break-word;background:#20231f;color:#f4f1e8;border-radius:8px;padding:10px;font-size:12px;max-height:220px;overflow:auto}",
    "@media(max-width:900px){.wrap{grid-template-columns:1fr}.feedback{position:static}}",
    "</style>",
    "</head>",
    "<body>",
    "<header>",
    paste0("<h1>", .html_escape(title), "</h1>"),
    '<div class="meta">Review-only artifact. Structured feedback must be imported back into R for validation before it affects any design object.</div>',
    "</header>",
    '<div class="wrap">',
    '<main class="main" id="main"></main>',
    '<aside class="panel feedback" id="feedbackPanel"></aside>',
    "</div>",
    '<script id="agentr-review-data" type="application/json">',
    as.character(payload_json),
    "</script>",
    '<script id="agentr-review-config" type="application/json">',
    as.character(config_json),
    "</script>",
    "<script>",
    "const data=JSON.parse(document.getElementById('agentr-review-data').textContent);",
    "const config=JSON.parse(document.getElementById('agentr-review-config').textContent);",
    "const feedback=[];",
    "const main=document.getElementById('main'); const panel=document.getElementById('feedbackPanel');",
    "function esc(x){return String(x??'').replace(/[&<>\"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',\"'\":'&#39;'}[m]));}",
    "function val(x){return x===null||x===undefined||x===''?'':x;}",
    "function section(title,id){const s=document.createElement('section');s.className='panel';s.id=id;s.innerHTML='<h2>'+esc(title)+'</h2>';main.appendChild(s);return s;}",
    "function selectTarget(target,targetId,field){if(!config.include_feedback_panel)return;document.getElementById('fb_target').value=target;document.getElementById('fb_target_id').value=targetId||'';document.getElementById('fb_field').value=field||target;}",
    "function wrapSvgText(text,maxChars=22){const words=String(text??'').split(/\\s+/).filter(Boolean);const lines=[];let line='';const pushLong=w=>{while(w.length>maxChars){lines.push(w.slice(0,maxChars));w=w.slice(maxChars);}return w;};words.forEach(word=>{word=pushLong(word);if(!word)return;if(!line){line=word;}else if((line+' '+word).length<=maxChars){line+=' '+word;}else{lines.push(line);line=word;}});if(line)lines.push(line);return lines.length?lines:[''];}",
    "function svgTspans(lines,x,startDy,lineHeight){return lines.map((line,i)=>`<tspan x='${x}' dy='${i===0?startDy:lineHeight}'>${esc(line)}</tspan>`).join('');}",
    "function drawWorkflowGraph(el,nodes,edges){const w=820,nodeW=180,colGap=250,rowGap=34,top=34,left=48;nodes.forEach((n,i)=>{n._lines=wrapSvgText(n.label,24);n._h=Math.max(62,40+n._lines.length*15);n._row=Math.floor(i/3);n._x=left+(i%3)*colGap;});const rows=Math.max(1,Math.ceil(nodes.length/3));const rowHeights=[];for(let r=0;r<rows;r++){const rowNodes=nodes.filter(n=>n._row===r);rowHeights[r]=rowNodes.length?Math.max(...rowNodes.map(n=>n._h)):62;}const rowY=[];let cursor=top;for(let r=0;r<rows;r++){rowY[r]=cursor;cursor+=rowHeights[r]+rowGap;}nodes.forEach(n=>{n._y=rowY[n._row];n._cy=n._y+n._h/2;});const h=Math.max(190,cursor-rowGap+top);let svg=`<svg viewBox='0 0 ${w} ${h}' width='100%' height='${h}' role='img' aria-label='Workflow graph'>`;svg+=`<defs><marker id='arrow' viewBox='0 0 10 10' refX='8' refY='5' markerWidth='6' markerHeight='6' orient='auto-start-reverse'><path d='M 0 0 L 10 5 L 0 10 z' fill='#6b7280'/></marker></defs>`;edges.forEach(e=>{const a=nodes.find(n=>n.id===e.from),b=nodes.find(n=>n.id===e.to);if(a&&b){svg+=`<line x1='${a._x+nodeW}' y1='${a._cy}' x2='${b._x}' y2='${b._cy}' stroke='#6b7280' stroke-width='1.5' marker-end='url(#arrow)'/>`;}});nodes.forEach(n=>{const tx=n._x+nodeW/2;svg+=`<g tabindex='0'><rect x='${n._x}' y='${n._y}' width='${nodeW}' height='${n._h}' rx='8' fill='${n.human_required?'#fff1d6':'#e8f3ee'}' stroke='#607466'/><text x='${tx}' y='${n._y+17}' text-anchor='middle' font-size='11'>${esc(n.id)}</text><text text-anchor='middle' font-size='12'>${svgTspans(n._lines,tx,n._y+34,15)}</text></g>`;});svg+='</svg>';el.innerHTML=svg;}",
    "function renderWorkflow(){if(!config.include_workflow)return;const s=section('Workflow graph','workflow');const g=document.createElement('div');g.className='graph';s.appendChild(g);drawWorkflowGraph(g,data.workflow_graph.nodes||[],data.workflow_graph.edges||[]);const grid=document.createElement('div');grid.className='grid';(data.workflow_graph.nodes||[]).forEach(n=>{const c=document.createElement('div');c.className='card';c.innerHTML=`<button><div class='id'>${esc(n.id)}</div><div class='label'>${esc(n.label)}</div><div class='small'>owner: ${esc(val(n.owner))} | automation: ${esc(val(n.automation_status))}</div><div class='small'>human gate: ${esc(n.human_required)} | review: ${esc(val(n.review_status))}</div><div class='small'>knowledge refs: ${esc((n.knowledge_refs||[]).join(', '))}</div></button>`;c.onclick=()=>selectTarget('workflow_node',n.id,'workflow.nodes.'+n.id);grid.appendChild(c);});s.appendChild(grid);const ebox=document.createElement('div');ebox.innerHTML='<h3>Edges</h3>';(data.workflow_graph.edges||[]).forEach(e=>{const d=document.createElement('div');d.className='edge';d.textContent=`${e.from} -> ${e.to} (${e.relation||'depends_on'})`;d.onclick=()=>selectTarget('workflow_edge',`${e.from}->${e.to}`,'workflow.edges');ebox.appendChild(d);});s.appendChild(ebox);}",
    "function renderKnowledge(){if(!config.include_knowledge)return;const s=section('Knowledge and graph knowledge','knowledge');const grid=document.createElement('div');grid.className='grid';(data.narrative_knowledge.items||[]).forEach(k=>{const c=document.createElement('div');c.className='card';c.innerHTML=`<button><div class='id'>${esc(k.id)}</div><div class='label'>${esc(k.type)}</div><div class='small'>${esc(k.normalized_statement||k.raw_statement)}</div></button>`;c.onclick=()=>selectTarget('knowledge_item',k.id,'knowledge.items.'+k.id);grid.appendChild(c);});(data.graph_knowledge.nodes||[]).forEach(n=>{const c=document.createElement('div');c.className='card';c.innerHTML=`<button><div class='id'>${esc(n.id)}</div><div class='label'>${esc(n.label)}</div><div class='small'>graph node: ${esc(n.node_type)}</div></button>`;c.onclick=()=>selectTarget('graph_node',n.id,'graph.nodes.'+n.id);grid.appendChild(c);});s.appendChild(grid);}",
    "function renderMemory(){if(!config.include_memory_schema)return;const s=section('Memory, state, and interface schema','memory');const grid=document.createElement('div');grid.className='grid';(data.memory_schema.fields||[]).forEach(f=>{const c=document.createElement('div');c.className='card';c.innerHTML=`<button><div class='id'>${esc(f.id)}</div><div class='label'>${esc(f.label)}</div><div class='small'>${esc(f.memory_type)} | ${esc(f.persistence)}</div><div class='small'>${esc(f.description)}</div></button>`;c.onclick=()=>selectTarget('memory_schema',f.id,'memory.fields.'+f.id);grid.appendChild(c);});s.appendChild(grid);['state_spec','interface_spec','autonomy_spec'].forEach(k=>{if(data.metadata&&data.metadata[k]){const pre=document.createElement('pre');pre.textContent=k+':\\n'+JSON.stringify(data.metadata[k],null,2);s.appendChild(pre);}});}",
    "function renderFeedback(){if(!config.include_feedback_panel){panel.style.display='none';return;}const schema=data.feedback_schema;panel.innerHTML=`<h2>Structured feedback</h2><div class='row'><label>Target</label><select id='fb_target'>${schema.targets.map(t=>`<option>${esc(t)}</option>`).join('')}</select></div><div class='row'><label>Target id</label><input id='fb_target_id'></div><div class='row'><label>Field</label><input id='fb_field' value='workflow_node'></div><div class='row'><label>Issue type</label><select id='fb_issue_type'>${schema.issue_types.map(t=>`<option>${esc(t)}</option>`).join('')}</select></div><div class='row'><label>Issue</label><textarea id='fb_issue'></textarea></div><div class='row'><label>Suggestion</label><textarea id='fb_suggestion'></textarea></div><div class='row'><label>Severity</label><select id='fb_severity'>${schema.severities.map(t=>`<option>${esc(t)}</option>`).join('')}</select></div><div class='btns'><button class='btn' id='addFb'>Add feedback</button><button class='btn secondary' id='copyFb'>Copy JSON</button><button class='btn secondary' id='downloadFb'>Download JSON</button></div><h3>Feedback JSON</h3><pre id='fb_json'>{\"feedback\":[]}</pre><div id='fb_list'></div>`;document.getElementById('addFb').onclick=addFeedback;document.getElementById('copyFb').onclick=()=>navigator.clipboard&&navigator.clipboard.writeText(document.getElementById('fb_json').textContent);document.getElementById('downloadFb').onclick=downloadFeedback;}",
    "function addFeedback(){const item={id:'fb_'+String(feedback.length+1).padStart(3,'0'),target:fb_target.value,target_id:fb_target_id.value,item_id:fb_target_id.value,field:fb_field.value,issue_type:fb_issue_type.value,issue:fb_issue.value,suggestion:fb_suggestion.value,severity:fb_severity.value,status:'open',source:'human',created_at:new Date().toISOString(),metadata:{review_id:data.review_id}};feedback.push(item);fb_issue.value='';fb_suggestion.value='';renderFeedbackList();}",
    "function renderFeedbackList(){const txt=JSON.stringify({feedback},null,2);document.getElementById('fb_json').textContent=txt;const list=document.getElementById('fb_list');list.innerHTML='';feedback.forEach((f,i)=>{const d=document.createElement('div');d.className='feedback-item';d.innerHTML=`<b>${esc(f.target)}</b> ${esc(f.target_id)}<br>${esc(f.issue)}<br><button class='btn secondary' data-i='${i}'>Delete</button>`;d.querySelector('button').onclick=()=>{feedback.splice(i,1);renderFeedbackList();};list.appendChild(d);});}",
    "function downloadFeedback(){const blob=new Blob([JSON.stringify({feedback},null,2)],{type:'application/json'});const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download=(data.review_id||'agentr_design_feedback')+'.json';a.click();URL.revokeObjectURL(a.href);}",
    "renderWorkflow();renderKnowledge();renderMemory();renderFeedback();",
    "</script>",
    "</body>",
    "</html>",
    sep = "\n"
  )
}

#' Export standalone design-review HTML
#'
#' @param x A [`DesignReviewSpec`] or any input accepted by
#'   [build_design_review_data()].
#' @param path Output HTML path.
#' @param ... Arguments passed to [design_review_html()].
#'
#' @return Invisibly returns the normalized output path.
#' @export
export_design_review_html <- function(x, path, ...) {
  html <- design_review_html(x, ...)
  writeLines(html, path, useBytes = TRUE)
  invisible(normalizePath(path, mustWork = FALSE))
}
