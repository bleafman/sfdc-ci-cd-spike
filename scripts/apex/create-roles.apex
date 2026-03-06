UserRole vp = new UserRole(Name='VP of Sales', DeveloperName='VP_Sales', RollupDescription='Top of sales hierarchy');
insert vp;
UserRole mgr = new UserRole(Name='Sales Manager', DeveloperName='Sales_Manager', ParentRoleId=vp.Id, RollupDescription='Reports to VP Sales');
insert mgr;
UserRole sdr = new UserRole(Name='SDR', DeveloperName='SDR', ParentRoleId=mgr.Id, RollupDescription='Front-line lead qualification');
insert sdr;
System.debug('Roles created: ' + vp.Id + ', ' + mgr.Id + ', ' + sdr.Id);
