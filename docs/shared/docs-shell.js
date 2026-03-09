(function () {
  function scopeDocStyles(cssText) {
    return cssText
      .replace(/\bhtml\s*,\s*body\b/g, ".doc-root")
      .replace(/\bbody\s*,\s*html\b/g, ".doc-root")
      .replace(/\bbody\b/g, ".doc-root")
      .replace(/\bhtml\b/g, ".doc-root");
  }

  function getParams() {
    return new URLSearchParams(window.location.search);
  }

  function setParams(params) {
    const query = params.toString();
    const nextUrl = query
      ? window.location.pathname + "?" + query
      : window.location.pathname;
    window.history.replaceState({}, "", nextUrl);
  }

  function escapeHtml(value) {
    return String(value || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function createDocsShell(config) {
    const {
      defaultTab,
      tabDefinitions,
      tabItemParams = {},
      elements,
      inlineDocBaseStyle = "",
      testingInlineMetaPattern = /^(Selection|Trigger|Environment|Platforms):/,
      prioritiesHeading = "To Do List",
    } = config;

    const {
      frame,
      fallback,
      requirementsView,
      requirementsList,
      requirementsHeading,
      requirementsToolbar,
      requirementsBackButton,
      docContent,
      tabButtons,
    } = elements;

    const catalogCache = {};
    const docCache = {};
    const requestState = {};
    let activeTab = pickTabFromUrl();

    function initRequestState() {
      Object.keys(tabDefinitions).forEach((tabKey) => {
        requestState[tabKey] = 0;
      });
    }

    function pickTabFromUrl() {
      const params = getParams();
      const requestedTab = params.get("tab") || "";
      if (tabDefinitions[requestedTab]) {
        return requestedTab;
      }
      return defaultTab;
    }

    function pickItemFromUrl(tabKey) {
      const key = tabItemParams[tabKey];
      if (!key) {
        return "";
      }
      const params = getParams();
      return params.get(key) || "";
    }

    function setTabInUrl(tabKey) {
      const params = getParams();
      params.set("tab", tabKey);
      Object.values(tabItemParams).forEach((paramName) => {
        if (tabItemParams[tabKey] !== paramName) {
          params.delete(paramName);
        }
      });
      if (tabItemParams[tabKey] && !params.get(tabItemParams[tabKey])) {
        params.delete(tabItemParams[tabKey]);
      }
      setParams(params);
    }

    function setTabItemInUrl(tabKey, itemKey) {
      const params = getParams();
      params.set("tab", tabKey);
      Object.values(tabItemParams).forEach((paramName) => {
        params.delete(paramName);
      });
      const key = tabItemParams[tabKey];
      if (key && itemKey) {
        params.set(key, itemKey);
      }
      setParams(params);
    }

    async function checkExists(path) {
      const response = await fetch(path, { method: "HEAD" });
      return response.ok;
    }

    function hideAllTabContent(invalidateKeys) {
      const keys = Array.isArray(invalidateKeys)
        ? invalidateKeys
        : Object.keys(tabDefinitions);
      keys.forEach((key) => {
        requestState[key] += 1;
      });

      frame.hidden = true;
      frame.removeAttribute("src");
      fallback.hidden = true;
      fallback.textContent = "";
      requirementsView.hidden = true;
      requirementsToolbar.hidden = true;
      docContent.hidden = true;
      if (docContent.shadowRoot) {
        docContent.shadowRoot.innerHTML = "";
      }
    }

    async function loadCatalog(tabKey) {
      if (catalogCache[tabKey]) {
        return catalogCache[tabKey];
      }
      const response = await fetch(tabDefinitions[tabKey].catalogUrl);
      if (!response.ok) {
        throw new Error("catalog unavailable");
      }
      catalogCache[tabKey] = await response.json();
      return catalogCache[tabKey];
    }

    async function loadDocPayload(url, tabKey) {
      if (docCache[url]) {
        return docCache[url];
      }

      const response = await fetch(url);
      if (!response.ok) {
        throw new Error("document unavailable");
      }

      const html = await response.text();
      const parsed = new DOMParser().parseFromString(html, "text/html");

      if (tabKey === "priorities" && parsed.body) {
        const firstHeading = parsed.body.querySelector("h1");
        if (firstHeading) {
          firstHeading.textContent = prioritiesHeading;
        } else {
          const heading = parsed.createElement("h1");
          heading.textContent = prioritiesHeading;
          parsed.body.insertBefore(heading, parsed.body.firstChild);
        }

        const paragraphs = Array.from(parsed.body.querySelectorAll("p"));
        paragraphs.forEach((paragraph) => {
          const text = (paragraph.textContent || "").trim();
          if (/^todo:\s*/i.test(text)) {
            paragraph.remove();
            return;
          }
          if (text === "Open items" || text === "Completed items") {
            const h2 = parsed.createElement("h2");
            h2.textContent = text;
            paragraph.replaceWith(h2);
          }
        });
      }

      if (tabKey === "testing" && parsed.body && url.includes("/test-lineup.html")) {
        const firstHeading = parsed.body.querySelector("h1");
        if (firstHeading) {
          firstHeading.textContent = "Test Lineup";
        }
        Array.from(parsed.body.querySelectorAll("p")).forEach((paragraph) => {
          const text = paragraph.textContent || "";
          if (testingInlineMetaPattern.test(text.trim())) {
            paragraph.classList.add("test-lineup-meta");
          }
        });
      }

      if (tabKey === "requirements" && parsed.body) {
        const anchors = Array.from(parsed.body.querySelectorAll("a"));
        anchors.forEach((anchor) => {
          const text = (anchor.textContent || "").trim().toLowerCase();
          if (text === "back to all requirements") {
            const parent = anchor.parentElement;
            if (
              parent &&
              parent.childElementCount === 1 &&
              (parent.tagName === "P" || parent.tagName === "DIV")
            ) {
              parent.remove();
              return;
            }
            anchor.remove();
          }
        });
      }

      const styleText = Array.from(parsed.querySelectorAll("style"))
        .map((styleNode) => styleNode.textContent || "")
        .join("\n");
      const payload = {
        bodyHtml: parsed.body ? parsed.body.innerHTML : "",
        title: parsed.title || "Document",
        styleText: scopeDocStyles(styleText),
      };
      docCache[url] = payload;
      return payload;
    }

    function renderInlineDoc(payload) {
      let shadowRoot = docContent.shadowRoot;
      if (!shadowRoot) {
        shadowRoot = docContent.attachShadow({ mode: "open" });
      }
      shadowRoot.innerHTML =
        "<style>" +
        inlineDocBaseStyle +
        payload.styleText +
        "</style>" +
        '<article class="doc-root" role="document" aria-label="' +
        escapeHtml(payload.title) +
        '">' +
        payload.bodyHtml +
        "</article>";
      docContent.hidden = false;
    }

    async function renderInlinePage(tabKey, tabConfig) {
      hideAllTabContent([tabKey]);
      const requestId = ++requestState[tabKey];
      try {
        const payload = await loadDocPayload(tabConfig.url, tabKey);
        if (requestId !== requestState[tabKey]) {
          return;
        }
        if (activeTab !== tabKey) {
          return;
        }
        renderInlineDoc(payload);
      } catch (error) {
        if (requestId !== requestState[tabKey]) {
          return;
        }
        hideAllTabContent();
        fallback.hidden = false;
        fallback.textContent = tabConfig.fallback;
      }
    }

    function renderCatalogList(tabKey, items, tabConfig) {
      requirementsList.innerHTML = "";
      requirementsHeading.textContent = tabConfig.heading || "Documents";
      requirementsToolbar.hidden = true;

      items.forEach((item) => {
        const link = document.createElement("button");
        link.type = "button";
        link.className = "requirements-link";
        link.textContent = item[tabConfig.itemTitle] || "";
        link.addEventListener("click", () => {
          setTabItemInUrl(tabKey, item[tabConfig.itemKey]);
          void renderCatalogItem(tabKey, item, tabConfig);
        });

        const summary = document.createElement("p");
        summary.className = "requirements-summary";
        summary.textContent = item[tabConfig.itemSummary] || "";

        const fragment = document.createDocumentFragment();
        fragment.appendChild(link);
        fragment.appendChild(summary);

        if (Array.isArray(tabConfig.metaFields)) {
          tabConfig.metaFields.forEach((entry) => {
            const meta = document.createElement("p");
            meta.className = "requirements-meta";
            const value = item[entry.key] || entry.defaultValue || "unknown";
            meta.textContent = entry.label + ": " + value;
            fragment.appendChild(meta);
          });
        }

        const container = document.createElement("li");
        container.className = "requirements-item";
        container.appendChild(fragment);
        requirementsList.appendChild(container);
      });
    }

    async function renderCatalogItem(tabKey, item, tabConfig) {
      const itemUrl = item[tabConfig.itemUrl];
      if (!itemUrl) {
        throw new Error("catalog item missing url");
      }

      if (tabConfig.inlineItemContent) {
        hideAllTabContent([tabKey]);
        const requestId = ++requestState[tabKey];
        requirementsToolbar.hidden = false;
        requirementsBackButton.textContent = tabConfig.backLabel || "Back to list";
        try {
          const payload = await loadDocPayload(itemUrl, tabKey);
          if (requestId !== requestState[tabKey]) {
            return;
          }
          const currentItem = pickItemFromUrl(tabKey);
          if (activeTab !== tabKey || currentItem !== item[tabConfig.itemKey]) {
            return;
          }
          renderInlineDoc(payload);
        } catch (error) {
          if (requestId !== requestState[tabKey]) {
            return;
          }
          hideAllTabContent();
          fallback.hidden = false;
          fallback.textContent = tabConfig.fallback;
          setTabItemInUrl(tabKey, "");
        }
        return;
      }

      hideAllTabContent();
      requirementsToolbar.hidden = false;
      requirementsBackButton.textContent = tabConfig.backLabel || "Back to list";
      frame.hidden = false;
      frame.src = itemUrl;
    }

    async function renderCatalog(tabKey, tabConfig) {
      try {
        const catalog = await loadCatalog(tabKey);
        const items = Array.isArray(catalog[tabConfig.listField])
          ? catalog[tabConfig.listField]
          : [];
        if (items.length === 0) {
          hideAllTabContent();
          fallback.hidden = false;
          fallback.textContent = tabConfig.fallback;
          setTabItemInUrl(tabKey, "");
          return;
        }

        const requestedKey = pickItemFromUrl(tabKey);
        const selectedItem = items.find(
          (entry) => entry[tabConfig.itemKey] === requestedKey
        );

        if (requestedKey && selectedItem) {
          await renderCatalogItem(tabKey, selectedItem, tabConfig);
          return;
        }

        setTabItemInUrl(tabKey, "");
        hideAllTabContent();
        requirementsView.hidden = false;
        renderCatalogList(tabKey, items, tabConfig);
      } catch (error) {
        hideAllTabContent();
        fallback.hidden = false;
        fallback.textContent = tabConfig.fallback;
        setTabItemInUrl(tabKey, "");
      }
    }

    async function renderTab(tabKey) {
      const nextTab = tabDefinitions[tabKey] ? tabKey : defaultTab;
      activeTab = nextTab;
      setTabInUrl(nextTab);
      tabButtons.forEach((button) => {
        button.setAttribute(
          "aria-selected",
          button.dataset.tabKey === nextTab ? "true" : "false"
        );
      });

      const tabConfig = tabDefinitions[nextTab];
      if (tabConfig.mode === "catalog") {
        await renderCatalog(nextTab, tabConfig);
        return;
      }

      if (tabConfig.mode === "inline-page") {
        await renderInlinePage(nextTab, tabConfig);
        return;
      }

      hideAllTabContent();
      try {
        const exists = await checkExists(tabConfig.url);
        if (!exists) {
          fallback.hidden = false;
          fallback.textContent = tabConfig.fallback;
          return;
        }
      } catch (error) {
        fallback.hidden = false;
        fallback.textContent = tabConfig.fallback;
        return;
      }

      frame.hidden = false;
      frame.src = tabConfig.url;
    }

    function init() {
      initRequestState();

      tabButtons.forEach((button) => {
        button.addEventListener("click", () => {
          void renderTab(button.dataset.tabKey || defaultTab);
        });
      });

      requirementsBackButton.addEventListener("click", () => {
        setTabItemInUrl(activeTab, "");
        void renderTab(activeTab);
      });

      void renderTab(activeTab);
    }

    return { init };
  }

  window.createDocsShell = createDocsShell;
})();
