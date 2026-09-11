import config from './acceptance.config.mjs';
process.env.CSIM_SIMPLE_CONTROLS='1';
process.env.CSIM_DASHBOARD_SLUG ||= 'csim-individual-simple';
export default {...config,testMatch:['**/month-controls.spec.mjs','**/whole-dashboard.spec.mjs','**/workflows.spec.mjs','**/fixture.spec.mjs','**/multiple-series.spec.mjs']};
