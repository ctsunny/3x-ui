const app = new Vue({
  delimiters: ['[[', ']]'],
  el: '#app',
  data: {
    themeSwitcher,
    loadingStates: { fetched: false, spinning: false },
    user: { username: "", password: "", twoFactorCode: "" },
    twoFactorEnable: false,
    lang: "",
    animationStarted: false
  },
  async mounted() {
    this.lang = LanguageManager.getLanguage();
    this.twoFactorEnable = await this.getTwoFactorEnable();
  },
  methods: {
    async login() {
      this.loadingStates.spinning = true;
      const msg = await HttpUtil.post('/login', this.user);
      if (msg.success) {
        location.href = basePath + 'panel/';
      }
      this.loadingStates.spinning = false;
    },
    async getTwoFactorEnable() {
      const msg = await HttpUtil.post('/getTwoFactorEnable');
      if (msg.success) {
        this.twoFactorEnable = msg.obj;
        this.loadingStates.fetched = true;
        this.$nextTick(() => {
          if (!this.animationStarted) {
            this.animationStarted = true;
            this.initHeadline();
          }
        });
        return msg.obj;
      }
    },
    initHeadline() {
      const animationDelay = 2000;
      const headlines = this.$el.querySelectorAll('.headline');
      headlines.forEach((headline) => {
        const first = headline.querySelector('.is-visible');
        if (!first) return;
        setTimeout(() => this.hideWord(first, animationDelay), animationDelay);
      });
    },
    hideWord(word, delay) {
      const nextWord = this.takeNext(word);
      this.switchWord(word, nextWord);
      setTimeout(() => this.hideWord(nextWord, delay), delay);
    },
    takeNext(word) {
      return word.nextElementSibling || word.parentElement.firstElementChild;
    },
    switchWord(oldWord, newWord) {
      oldWord.classList.remove('is-visible');
      oldWord.classList.add('is-hidden');
      newWord.classList.remove('is-hidden');
      newWord.classList.add('is-visible');
    }
  },
});

const pm_input_selector = 'input.ant-input, textarea.ant-input';
const pm_strip_props = [
  'background',
  'background-color',
  'background-image',
  'color'
];

const pm_observed_forms = new WeakSet();

function pm_strip_inline(el) {
  if (!el || el.nodeType !== 1 || !el.matches?.(pm_input_selector)) return;

  let did_change = false;
  for (const prop of pm_strip_props) {
    if (el.style.getPropertyValue(prop)) {
      el.style.removeProperty(prop);
      did_change = true;
    }
  }

  if (did_change && el.style.length === 0) {
    el.removeAttribute('style');
  }
}

function pm_attach_observer(form) {
  if (pm_observed_forms.has(form)) return;
  pm_observed_forms.add(form);

  form.querySelectorAll(pm_input_selector).forEach(pm_strip_inline);

  const pm_mo = new MutationObserver(mutations => {
    for (const m of mutations) {
      if (m.type === 'attributes') {
        pm_strip_inline(m.target);
      } else if (m.type === 'childList') {
        for (const n of m.addedNodes) {
          if (n.nodeType !== 1) continue;
          if (n.matches?.(pm_input_selector)) pm_strip_inline(n);
          n.querySelectorAll?.(pm_input_selector).forEach(pm_strip_inline);
        }
      }
    }
  });

  pm_mo.observe(form, {
    attributes: true,
    attributeFilter: ['style'],
    childList: true,
    subtree: true
  });
}

function pm_init() {
  document.querySelectorAll('form.ant-form').forEach(pm_attach_observer);
  const pm_host = document.getElementById('login') || document.body;
  const pm_wait_for_forms = new MutationObserver(mutations => {
    for (const m of mutations) {
      for (const n of m.addedNodes) {
        if (n.nodeType !== 1) continue;
        if (n.matches?.('form.ant-form')) pm_attach_observer(n);
        n.querySelectorAll?.('form.ant-form').forEach(pm_attach_observer);
      }
    }
  });
  pm_wait_for_forms.observe(pm_host, { childList: true, subtree: true });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', pm_init, { once: true });
} else {
  pm_init();
}
