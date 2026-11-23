// CRM: entry point of our own interface (crm/PRD.md, stage D).
import '../crm/styles.css';
import { createApp } from 'vue';
import App from '../crm/App.vue';
import router from '../crm/router';

createApp(App).use(router).mount('#crm-app');
