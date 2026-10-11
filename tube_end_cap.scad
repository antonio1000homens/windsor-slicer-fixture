/*
  Parametric flanged push-in cap for a thin-wall round metal tube.
  Photo-derived starting values only. Verify actual tube INSIDE diameter with
  calipers and adjust tube_inner_diameter before printing the final cap.

  Printing: flange flat on build plate, plug facing up, no supports.
  Material: PETG or ASA for outdoors. Not structural or load bearing.
  Available modes: "cap" and "fit_test" (short trial version).
*/

// ---- Measurements (mm) ----------------------------------------------
tube_outer_diameter = 40.0;       // ESTIMATE from photographs, NOT a precise reading
tube_inner_diameter = 37.4;       // ESTIMATE: check with internal caliper jaws

// ---- Fit settings (mm) -----------------------------------------------
radial_clearance = 0.25;         // one side: 0.15 tight, 0.25 nominal, 0.4 loose
retention_bump_height = 0.28;    // gentle compression ribs; set 0 for smooth
flange_overhang = 2.0;          // radial overhang beyond OUTSIDE wall
flange_thickness = 3.0;
insertion_depth = 18.0;
plug_wall = 2.0;
entry_chamfer_height = 2.0;
slot_width = 1.6;               // four slots allow flexing of plug fingers
finger_root_height = 4.0;       // unslotted section at flange

// ---- Output ----------------------------------------------------------
mode = "cap"; // [cap,fit_test]
$fn = 96;

// Geometry safeguards
assert(tube_outer_diameter > tube_inner_diameter, "OD must exceed ID");
assert(tube_inner_diameter > 2*plug_wall + 10, "Insufficient inner clearance");
assert(radial_clearance >= 0, "Radial clearance must not be negative");

plug_diameter = tube_inner_diameter - 2*radial_clearance;
flange_diameter = tube_outer_diameter + 2*flange_overhang;
plug_height = mode == "fit_test" ? 9 : insertion_depth;
root_height = min(finger_root_height, plug_height / 2);

module grip_body() {
    // Outer plug has slightly narrower nose for easier insertion.
    union() {
        cylinder(d=plug_diameter, h=max(0.01,plug_height-entry_chamfer_height));
        translate([0,0,plug_height-entry_chamfer_height])
            cylinder(d1=plug_diameter, d2=plug_diameter-1.0,
                     h=entry_chamfer_height);
        // Compressible, narrow raised band near the nose; no dependence on
        // the tube's side apertures being a particular distance from its end.
        if (retention_bump_height > 0)
            translate([0,0,max(root_height+1,plug_height-entry_chamfer_height-3)])
                cylinder(d1=plug_diameter, d2=plug_diameter+2*retention_bump_height,
                         h=0.7);
        if (retention_bump_height > 0)
            translate([0,0,max(root_height+1,plug_height-entry_chamfer_height-3)+0.7])
                cylinder(d1=plug_diameter+2*retention_bump_height,
                         d2=plug_diameter, h=0.9);
    }
}

module cap() {
    difference() {
        union() {
            // Closed face. Small chamfer on face rim to reduce sharp edges.
            cylinder(d1=flange_diameter-0.6, d2=flange_diameter,
                     h=0.6);
            translate([0,0,0.6])
                cylinder(d=flange_diameter,h=flange_thickness-0.6);
            translate([0,0,flange_thickness]) grip_body();
        }

        // Hollow sleeve, starts over the solid end plate (no hole through face).
        translate([0,0,flange_thickness])
            cylinder(d=plug_diameter-2*plug_wall,h=plug_height+0.2);

        // Axial compliant slits: don't penetrate the solid flange or plug root.
        for (angle=[0,90,180,270])
            rotate([0,0,angle])
                translate([-slot_width/2,-(flange_diameter+2)/2,
                           flange_thickness+root_height])
                    cube([slot_width,(flange_diameter+2)/2,plug_height-root_height+0.2]);
    }
}

cap();
