class RpsParcel < ActiveRecord::Base

=BEGIN



insert into
rps_parcels
(swis, sbl, no, street_prefix, street_name, street_type, street_suffix, zip, town, village, school)
select

Swis, SBL,
LocStNbr,
LocStPDir,
LocStName,
LocStType,
LocStSDir,
LocZipCode,
TwnTxble,
VilTxble,
SclTxble

from RealProperty.tblAssessment a
where a.LocStName != ''
and PropClass between 200 and 299;

update rps_parcels set village = null where village = 0;

update rps_parcels set street_full = street_name, search = street_name;
update rps_parcels set street_full = concat(street_prefix, ' ', street_full) where street_prefix != '';
update rps_parcels set street_full = concat(street_full, ' ', street_type) where street_type != '';
update rps_parcels set street_full = concat(street_full, ' ', street_suffix) where street_suffix != '';

update rps_parcels set search = concat('North N ', search) where street_prefix = 'N';
update rps_parcels set search = concat('East E ', search) where street_prefix = 'E';
update rps_parcels set search = concat('South S ', search) where street_prefix = 'S';
update rps_parcels set search = concat('West W ', search) where street_prefix = 'W';

update rps_parcels p set p.search = concat(p.search, ' ', p.street_type) where p.street_type != '';

update rps_parcels p
join (select word, group_concat(v.variant separator ' ') variant from hr_apply_online.address_variants v group by word) v on p.street_type = v.word 
set p.search = concat(p.search, ' ', v.variant);


update rps_parcels set search = concat(search, 'North N ') where street_suffix = 'N';
update rps_parcels set search = concat(search, 'East E ') where street_suffix = 'E';
update rps_parcels set search = concat(search, 'South S ') where street_suffix = 'S';
update rps_parcels set search = concat(search, 'West W ') where street_suffix = 'W';

update rps_parcels set no_min = no;
update rps_parcels set no_max = no;

update rps_parcels set no_max = substring_index(no, '-', -1) where no like "%-%";

update rps_parcels set no_max = no_min where no_max = 0;

update rps_parcels p
set town = swis;


update rps_parcels p
set village = null;

update rps_parcels p
set town = '262489', # CLARKSON
village = '262401' # BROCKPORT (CL)
where swis = '262401';

update rps_parcels p
set town = '263689', # MENDON
village = '263601' # HONEOYE FALLS
where swis = '263601';

update rps_parcels p
set town = '263889', # OGDEN
village = '263801' # SPENCERPORT
where swis = '263801';

update rps_parcels p
set town = '264089', # PARMA
village = '264001' # HILTON
where swis = '264001';

update rps_parcels p
set town = '264489', # PERINTON
village = '264403' # FAIRPORT
where swis = '264403';

update rps_parcels p
set town = '264689', # PITTSFORD (T)
village = '264601' # PITTSFORD (V)
where swis = '264601';

update rps_parcels p
set town = '264889', # RIGA
village = '264801' # CHURCHVILLE
where swis = '264801';

update rps_parcels p
set town = '265289', # SWEDEN
village = '265201' # BROCKPORT(S)
where swis = '265201';				


update rps_parcels p
set town = '265489', # WEBSTER
village = '265401' # WEBSTER (V)
where swis = '265401';

update rps_parcels p
set town = '265689', # WHEATLAND
village = '265601' # SCOTTSVILLE
where swis = '265601';	

update rps_parcels p
set town = '265689', # WHEATLAND
village = '265601' # SCOTTSVILLE
where swis = '265601';	

update rps_parcels p
set town = '265889', # EAST ROCHESTER
village = '265801' # EAST ROCHESTER
where swis = '265801';				

update rps_parcels p
set town = '261400', # ROCHESTER
village = '261400' # ROCHESTER
where swis = '261400';	




=END


end