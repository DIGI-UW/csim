import copy
import json
import unittest
from pathlib import Path
from update_panel_coverage import proposed, verify

ROOT = Path(__file__).resolve().parents[1]

class PanelCoverage(unittest.TestCase):
    def setUp(self):
        self.before = json.loads((ROOT/'sources/live-review/2026-09-17T163028Z/inventory.json').read_text())
        self.plan = json.loads((ROOT/'dashboard/overlays/beth-panel-coverage.json').read_text())

    def test_only_approved_fields_change_on_beths_saved_dashboard(self):
        payload, charts = proposed(self.before, self.plan)
        ids = {85,86,88,92,94,95,97}
        self.assertEqual(set(charts), ids)
        old = self.before['dashboard']['definition']
        metadata = json.loads(payload['json_metadata'])
        original = json.loads(old['json_metadata'])
        for control in metadata['native_filter_configuration']:
            if control['id'] in self.plan['filters']:
                self.assertTrue(ids.issubset(control['scope']['excluded']))
                self.assertFalse(ids.intersection(control['chartsInScope']))
                prior = next(f for f in original['native_filter_configuration'] if f['id']==control['id'])
                # Restoring these two fields must make every control and all
                # palette/default/other metadata identical to Beth's version.
                control['scope']['excluded'] = prior['scope']['excluded']
                control['chartsInScope'] = prior['chartsInScope']
        self.assertEqual(metadata, original)
        position = json.loads(payload['position_json']); prior = json.loads(old['position_json'])
        for key,node in position.items():
            if isinstance(node,dict) and node.get('type')=='CHART' and node['meta']['chartId'] in ids:
                node['meta']['sliceNameOverride'] = prior[key]['meta']['sliceNameOverride']
        self.assertIn('Number of submissions with a positive urinalysis',position[self.plan['formulaNode']]['meta']['code'])
        self.assertNotIn('treated asymptomatic',position[self.plan['formulaNode']]['meta']['code'])
        position[self.plan['formulaNode']]['meta']['code'] = prior[self.plan['formulaNode']]['meta']['code']
        self.assertEqual(position, prior)
        self.assertEqual(proposed({**self.before,'dashboard':{**self.before['dashboard'],'definition':{**old,**payload}}}, self.plan), (payload, charts))

    def test_resolves_different_destination_chart_ids_by_uuid(self):
        before=copy.deepcopy(self.before); definition=before['dashboard']['definition']
        position=json.loads(definition['position_json']); metadata=json.loads(definition['json_metadata'])
        for c in before['charts']: c['id']+=1000
        for n in position.values():
            if isinstance(n,dict) and n.get('type')=='CHART': n['meta']['chartId']+=1000
        for f in metadata['native_filter_configuration']:
            if 'scope' in f: f['scope']['excluded']=[id+1000 for id in f['scope']['excluded']]
            if 'chartsInScope' in f: f['chartsInScope']=[id+1000 for id in f['chartsInScope']]
        definition.update(position_json=json.dumps(position),json_metadata=json.dumps(metadata))
        payload,charts=proposed(before,self.plan)
        self.assertEqual(set(charts),{1085,1086,1088,1092,1094,1095,1097})

    def test_post_write_verification_rejects_calculation_or_layout_changes(self):
        payload,charts=proposed(self.before,self.plan)
        after=copy.deepcopy(self.before); after['dashboard']['definition'].update(payload)
        for c in after['charts']:c['definition'].update(charts.get(c['id'],{}))
        verify(self.before,after,payload,charts)
        after['charts'][0]['definition']['params']='{}'
        with self.assertRaises(AssertionError):verify(self.before,after,payload,charts)

if __name__=='__main__':unittest.main()
