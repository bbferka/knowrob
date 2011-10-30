package de.tum.in.fipm.kipm.gui.visualisation.items;

import javax.vecmath.Matrix4d;
import javax.vecmath.Vector3d;

import edu.tum.cs.vis.Canvas;
import edu.tum.cs.vis.model.ItemModel;

public class Bottle extends Item {
	
	public Bottle(float m00, float m01, float m02, float m03, float m10,
			float m11, float m12, float m13, float m20, float m21, float m22,
			float m23, float m30, float m31, float m32, float m33, float xdim,
			float ydim, float zdim) {
		super(m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31,
				m32, m33, xdim, ydim, zdim);
		model = new ItemModel(colladaFile);
	}

	public Bottle(Matrix4d pose, Vector3d dim){
		super(pose, dim);
		model = new ItemModel(colladaFile);
	}
	
	/*@Override
	public void drawIt(Canvas c) {
		
		(new Cylinder(new Vector3f(0f, 0f, 0f), new Vector3f(0f, 0f, 15f), 0.04f)).draw(c); // cup
		(new Cylinder(new Vector3f(0f, 0f, 15f), new Vector3f(0f, 0f, 25f), 0.015f)).draw(c); // nozzle
		
	}*/

	
	/*
	 * Modified for testing with collada
	 */
	
	private static String colladaFile = "/home/stefan/Coke2.dae";
	
	@Override
	public void drawIt(Canvas c) {
		model.getParser().draw(c);
		c.noFill();
		c.strokeWeight(1);
		c.stroke(204, 120, 15);
		model.getParser().drawBoundingBox(c);
	}
}
