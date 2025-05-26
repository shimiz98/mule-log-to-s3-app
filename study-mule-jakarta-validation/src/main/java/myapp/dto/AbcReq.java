package myapp.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;

public class AbcReq {
	@NotBlank
	String a;
	String b;
	@Valid
	C c;
	
	public static class C {
		@NotBlank
		String ca;
		String cb;
		String cc;
		public String getCa() {
			return ca;
		}
		public void setCa(String ca) {
			this.ca = ca;
		}
		public String getCb() {
			return cb;
		}
		public void setCb(String cb) {
			this.cb = cb;
		}
		public String getCc() {
			return cc;
		}
		public void setCc(String cc) {
			this.cc = cc;
		}	
	}

	public String getA() {
		return a;
	}

	public void setA(String a) {
		this.a = a;
	}

	public String getB() {
		return b;
	}

	public void setB(String b) {
		this.b = b;
	}

	public C getC() {
		return c;
	}

	public void setC(C c) {
		this.c = c;
	}
}
