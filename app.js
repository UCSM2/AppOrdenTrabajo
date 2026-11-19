async function api(url, opts = {}) {
  const res = await fetch(url, {
    headers: { "Content-Type": "application/json" },
    ...opts,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    if (res.status === 401 && !location.pathname.endsWith("login.html")) {
      location.href = "/login.html";
    }
    throw new Error(data.error || "Error en la operación");
  }
  return data;
}

function showAlert(msg, isError = true) {
  const el = document.getElementById("global-alert");
  if (!el) return;
  el.textContent = msg;
  el.className = `alert ${isError ? "alert-error" : "alert-ok"}`;
  setTimeout(() => el.classList.add("hidden"), 5000);
}

// 1. LÓGICA DE LOGIN
if (document.getElementById("login-form")) {
  document.getElementById("login-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const errEl = document.getElementById("login-error");
    errEl.classList.add("hidden");
    try {
      await api("/api/login", {
        method: "POST",
        body: JSON.stringify({
          username: document.getElementById("username").value,
          password: document.getElementById("password").value,
        }),
      });
      location.href = "/index.html";
    } catch (err) {
      errEl.textContent = err.message;
      errEl.classList.remove("hidden");
    }
  });
}

// 2. LÓGICA DEL INFORME IMPRIMIBLE
if (document.getElementById("doc-sheet")) {
  document.getElementById("btn-print").onclick = () => window.print();
  document.getElementById("btn-close").onclick = () => window.close();

  (async () => {
    const cod = new URLSearchParams(location.search).get("cod");
    if (!cod) return;
    try {
      const data = await api(`/api/informe?cod=${encodeURIComponent(cod)}`);
      const c = data.cabecera;
      document.getElementById("inf-cod").textContent = c.coddocumento;
      document.getElementById("inf-desc").textContent = c.descripcion;
      document.getElementById("inf-enc").textContent = c.encargado;
      document.getElementById("inf-fecha").textContent = c.fecha;
      document.getElementById("inf-estado").textContent = c.estado;

      const fill = (id, rows, cols) => {
        const tb = document.getElementById(id);
        tb.innerHTML = rows.length
          ? rows.map((r) => `<tr>${cols.map((k) => `<td>${r[k] ?? "-"}</td>`).join("")}</tr>`).join("")
          : `<tr><td colspan="${cols.length}">Sin registros asignados</td></tr>`;
      };
      fill("inf-personas", data.personas, ["cantidad", "horas_hombre", "especialidad"]);
      fill("inf-materiales", data.materiales, ["cantidad", "descripcion", "codrepuesto", "codfabricante"]);
      fill("inf-herramientas", data.herramientas, ["cantidad", "horas", "descripcion"]);
      fill("inf-maquinaria", data.maquinaria, ["cantidad", "horas", "descripcion"]);
    } catch (err) {
      alert(err.message);
    }
  })();
}

// 3. LÓGICA DEL DASHBOARD PRINCIPAL
if (document.querySelector(".app-layout")) {
  let state = { user: null, catalogos: null, tab: "ordenes", editCod: null, items: { personas: [], materiales: [], herramientas: [], maquinaria: [] }, reportes: [] };

  const CRUD_CFG = {
    persona: { title: "Gestión de Personal", cols: ["codigo", "especialidad"], headers: ["Código", "Especialidad"] },
    maquinaria: { title: "Gestión de Maquinaria", cols: ["codigo", "descripcion"], headers: ["Código", "Descripción"] },
    herramientas: { title: "Gestión de Herramientas", cols: ["codigo", "descripcion"], headers: ["Código", "Descripción"] },
    materiales: { title: "Gestión de Materiales", cols: ["codigo", "descripcion", "codrepuesto", "codfabricante"], headers: ["Código", "Descripción", "Repuesto", "Fabricante"] },
  };

  async function init() {
    state.user = await api("/api/me");
    document.getElementById("user-info").textContent = `${state.user.username} (${state.user.rol})`;
    await reloadCatalogos();
    await loadOrdenes();
    state.reportes = await api("/api/reportes");
    const repSel = document.getElementById("rep-select");
    repSel.innerHTML = state.reportes.map((r) => `<option value="${r.id}">${r.id}. ${r.titulo}</option>`).join("");
    repSel.onchange = () => {
      const r = state.reportes.find((x) => x.id == repSel.value);
      document.getElementById("rep-desc").textContent = r ? r.descripcion : "";
    };
    repSel.dispatchEvent(new Event("change"));
  }

  async function reloadCatalogos() {
    state.catalogos = await api("/api/catalogos");
    const cat = state.catalogos;
    document.getElementById("ord-encargado").innerHTML = cat.encargados.map((e) => `<option value="${e.codigo}">${e.nombre}</option>`).join("");
    const estOpts = cat.estados.map((e) => `<option value="${e}">${e}</option>`).join("");
    document.getElementById("ord-estado").innerHTML = estOpts;
    document.getElementById("fil-estado").innerHTML = `<option value="">Todos los estados</option>${estOpts}`;
    document.getElementById("rep-estado").innerHTML = `<option value="">Todos</option>${estOpts}`;

    document.getElementById("sel-persona").innerHTML = cat.personas.map((p) => `<option value="${p.codigo}">${p.codigo} - ${p.especialidad}</option>`).join("");
    document.getElementById("sel-materiales").innerHTML = cat.materiales.map((m) => `<option value="${m.codigo}">${m.codigo} - ${m.descripcion}</option>`).join("");
    document.getElementById("sel-herramientas").innerHTML = cat.herramientas.map((h) => `<option value="${h.codigo}">${h.codigo} - ${h.descripcion}</option>`).join("");
    document.getElementById("sel-maquinaria").innerHTML = cat.maquinaria.map((m) => `<option value="${m.codigo}">${m.codigo} - ${m.descripcion}</option>`).join("");
  }

  // Navegación
  document.querySelectorAll(".nav-btn").forEach((btn) => {
    btn.onclick = () => {
      document.querySelectorAll(".nav-btn").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      const tab = btn.dataset.tab;
      state.tab = tab;
      document.querySelectorAll(".tab-panel").forEach((p) => p.classList.remove("active"));
      if (CRUD_CFG[tab]) {
        document.getElementById("tab-crud").classList.add("active");
        setupCrud(tab);
      } else {
        document.getElementById(`tab-${tab}`).classList.add("active");
      }
    };
  });

  document.getElementById("btn-logout").onclick = async () => {
    await api("/api/logout", { method: "POST" });
    location.href = "/login.html";
  };

  // Órdenes
  document.getElementById("btn-toggle-orden").onclick = () => document.getElementById("form-orden").classList.toggle("hidden");
  document.getElementById("btn-bus-ordenes").onclick = loadOrdenes;

  document.querySelectorAll("[data-add]").forEach((btn) => {
    btn.onclick = () => {
      const tipo = btn.dataset.add;
      const selMap = { personas: "sel-persona", materiales: "sel-materiales", herramientas: "sel-herramientas", maquinaria: "sel-maquinaria" };
      const sel = document.getElementById(selMap[tipo]);
      const cant = parseInt(document.getElementById(`cant-${tipo}`).value, 10);
      const hrsEl = document.getElementById(`hrs-${tipo}`);
      const horas = hrsEl ? parseFloat(hrsEl.value) : null;
      if (!cant || cant <= 0 || (hrsEl && (!horas || horas <= 0))) return showAlert("Ingrese cantidad y horas válidas.");
      state.items[tipo].push({ codigo: sel.value, label: sel.options[sel.selectedIndex].text, cantidad: cant, horas });
      renderItems(tipo);
    };
  });

  function renderItems(tipo) {
    const ul = document.getElementById(`list-${tipo}`);
    ul.innerHTML = state.items[tipo].map((it, i) => `<li><span>${it.label} | Cant: ${it.cantidad}${it.horas ? ` | Hrs: ${it.horas}` : ""}</span><button type="button" data-del="${tipo}:${i}">x</button></li>`).join("");
    ul.querySelectorAll("button").forEach((b) => {
      b.onclick = () => {
        const [t, idx] = b.dataset.del.split(":");
        state.items[t].splice(Number(idx), 1);
        renderItems(t);
      };
    });
  }

  document.getElementById("form-orden").onsubmit = async (e) => {
    e.preventDefault();
    try {
      const res = await api("/api/ordenes", {
        method: "POST",
        body: JSON.stringify({
          codencargado: document.getElementById("ord-encargado").value,
          fecha: document.getElementById("ord-fecha").value,
          estado: document.getElementById("ord-estado").value,
          descripcion: document.getElementById("ord-desc").value,
          ...state.items,
        }),
      });
      showAlert(`Orden ${res.coddocumento} registrada correctamente.`, false);
      state.items = { personas: [], materiales: [], herramientas: [], maquinaria: [] };
      ["personas", "materiales", "herramientas", "maquinaria"].forEach(renderItems);
      e.target.reset();
      e.target.classList.add("hidden");
      await loadOrdenes();
    } catch (err) {
      showAlert(err.message);
    }
  };

  async function loadOrdenes() {
    const q = document.getElementById("bus-ordenes").value;
    const est = document.getElementById("fil-estado").value;
    const rows = await api(`/api/ordenes?q=${encodeURIComponent(q)}&estado=${encodeURIComponent(est)}`);
    const tb = document.getElementById("tbl-ordenes");
    tb.innerHTML = rows.map((r) => `
      <tr>
        <td><strong>${r.coddocumento}</strong></td>
        <td>${r.descripcion}</td>
        <td>${r.encargado}</td>
        <td>${r.fecha}</td>
        <td>
          <select class="est-change" data-cod="${r.coddocumento}">
            ${state.catalogos.estados.map((e) => `<option value="${e}" ${e === r.estado ? "selected" : ""}>${e}</option>`).join("")}
          </select>
        </td>
        <td><a class="btn btn-sm btn-primary" href="/informe.html?cod=${encodeURIComponent(r.coddocumento)}" target="_blank">Informe PDF</a></td>
      </tr>`).join("");

        tb.querySelectorAll(".est-change").forEach((sel) => {
      sel.onchange = async () => {
        try {
          await api(`/api/ordenes/${encodeURIComponent(sel.dataset.cod)}/estado`, {
            method: "PUT",
            body: JSON.stringify({ estado: sel.value }),
          });
          showAlert("Estado actualizado.", false);
        } catch (err) {
          showAlert(err.message);
          loadOrdenes();
        }
      };
    });
  }

  // CRUD Entidades
  async function setupCrud(tipo) {
    state.editCod = null;
    const cfg = CRUD_CFG[tipo];
    document.getElementById("crud-title").textContent = cfg.title;
    document.getElementById("crud-form-title").textContent = "Nuevo Registro";
    document.getElementById("btn-crud-cancel").classList.add("hidden");

    const sig = await api(`/api/siguiente-codigo?tipo=${tipo}`);
    const fields = document.getElementById("crud-fields");

    if (tipo === "materiales") {
      fields.innerHTML = `
        <div class="form-group">
          <label>Código</label>
          <input id="f-codigo" value="${sig.codigo}" required>
        </div>
        <div class="form-group">
          <label>Repuesto</label>
          <select id="f-codrepuesto">
            ${state.catalogos.repuestos.map((r) => `<option value="${r.codigo}">${r.codigo}</option>`).join("")}
          </select>
        </div>
        <div class="form-group">
          <label>Fabricante</label>
          <select id="f-codfabricante">
            ${state.catalogos.fabricantes.map((f) => `<option value="${f.codigo}">${f.codigo}</option>`).join("")}
          </select>
        </div>
        <div class="form-group">
          <label>Descripción</label>
          <input id="f-descripcion" required>
        </div>`;
    } else if (tipo === "persona") {
      fields.innerHTML = `
        <div class="form-group">
          <label>Código</label>
          <input id="f-codigo" value="${sig.codigo}" required>
        </div>
        <div class="form-group">
          <label>Especialidad</label>
          <input id="f-especialidad" required>
        </div>`;
    } else {
      fields.innerHTML = `
        <div class="form-group">
          <label>Código</label>
          <input id="f-codigo" value="${sig.codigo}" required>
        </div>
        <div class="form-group">
          <label>Descripción</label>
          <input id="f-descripcion" required>
        </div>`;
    }

    await loadCrudRows();
  }

  document.getElementById("btn-bus-crud").onclick = loadCrudRows;
  document.getElementById("btn-crud-cancel").onclick = () => setupCrud(state.tab);

  async function loadCrudRows() {
    const tipo = state.tab;
    const cfg = CRUD_CFG[tipo];
    const q = document.getElementById("bus-crud").value;
    const rows = await api(`/api/${tipo}?q=${encodeURIComponent(q)}`);

    document.getElementById("thead-crud").innerHTML = `
      <tr>
        ${cfg.headers.map((h) => `<th>${h}</th>`).join("")}
        <th>Acciones</th>
      </tr>`;

    const tb = document.getElementById("tbody-crud");
    tb.innerHTML = rows.map((r) => `
      <tr>
        ${cfg.cols.map((c) => `<td>${r[c]}</td>`).join("")}
        <td>
          <button class="btn btn-sm" data-edit='${JSON.stringify(r)}'>Editar</button>
          <button class="btn btn-sm btn-danger" data-del="${r.codigo}">Eliminar</button>
        </td>
      </tr>`).join("");

    tb.querySelectorAll("[data-edit]").forEach((b) => {
      b.onclick = () => {
        const r = JSON.parse(b.dataset.edit);
        state.editCod = r.codigo;
        document.getElementById("crud-form-title").textContent = `Editando ${r.codigo}`;
        document.getElementById("btn-crud-cancel").classList.remove("hidden");
        document.getElementById("f-codigo").value = r.codigo;
        document.getElementById("f-codigo").disabled = true;

        if (r.especialidad) document.getElementById("f-especialidad").value = r.especialidad;
        if (r.descripcion) document.getElementById("f-descripcion").value = r.descripcion;
        if (r.codrepuesto) document.getElementById("f-codrepuesto").value = r.codrepuesto;
        if (r.codfabricante) document.getElementById("f-codfabricante").value = r.codfabricante;
      };
    });

    tb.querySelectorAll("[data-del]").forEach((b) => {
      b.onclick = async () => {
        if (!confirm(`¿Dar de baja lógica el registro ${b.dataset.del}?`)) return;
        try {
          await api(`/api/${tipo}/${encodeURIComponent(b.dataset.del)}`, {
            method: "DELETE",
          });
          showAlert("Registro dado de baja.", false);
          await reloadCatalogos();
          await loadCrudRows();
        } catch (err) {
          showAlert(err.message);
        }
      };
    });
  }

  document.getElementById("form-crud").onsubmit = async (e) => {
    e.preventDefault();
    const tipo = state.tab;
    const payload = { codigo: document.getElementById("f-codigo").value };

    if (document.getElementById("f-especialidad")) {
      payload.especialidad = document.getElementById("f-especialidad").value;
    }
    if (document.getElementById("f-descripcion")) {
      payload.descripcion = document.getElementById("f-descripcion").value;
    }
    if (document.getElementById("f-codrepuesto")) {
      payload.codrepuesto = document.getElementById("f-codrepuesto").value;
    }
    if (document.getElementById("f-codfabricante")) {
      payload.codfabricante = document.getElementById("f-codfabricante").value;
    }

    try {
      if (state.editCod) {
        await api(`/api/${tipo}/${encodeURIComponent(state.editCod)}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });
        showAlert("Registro actualizado.", false);
      } else {
        await api(`/api/${tipo}`, {
          method: "POST",
          body: JSON.stringify(payload),
        });
        showAlert("Registro creado.", false);
      }
      await reloadCatalogos();
      await setupCrud(tipo);
    } catch (err) {
      showAlert(err.message);
    }
  };

  // Reportes
  document.getElementById("btn-run-rep").onclick = async () => {
    const id = document.getElementById("rep-select").value;
    const desde = document.getElementById("rep-desde").value;
    const hasta = document.getElementById("rep-hasta").value;
    const estado = document.getElementById("rep-estado").value;

    try {
      const res = await api(`/api/reportes/${id}?desde=${desde}&hasta=${hasta}&estado=${encodeURIComponent(estado)}`);
      document.getElementById("thead-rep").innerHTML = `
        <tr>
          ${res.columns.map((c) => `<th>${c.replace(/_/g, " ")}</th>`).join("")}
        </tr>`;
      document.getElementById("tbody-rep").innerHTML = res.rows.length
        ? res.rows.map((r) => `
            <tr>
              ${res.columns.map((c) => `<td>${r[c] ?? "-"}</td>`).join("")}
            </tr>`).join("")
        : `<tr><td colspan="${res.columns.length}">Sin resultados para los filtros seleccionados</td></tr>`;
    } catch (err) {
      showAlert(err.message);
    }
  };

  init().catch((err) => showAlert(err.message));
}
