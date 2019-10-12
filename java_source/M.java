package oldtests;

public class M {

	public int calc1(int a) {
		return f(a);
	}

	public int f(int num) {
		if(num == 0) {
			return 1;
		} else {
			int a = f(num - 1);
			return g(a) + calc1(10);
		}
	}

	public int g(int num) {
		if(num == 0) {
			return 1;
		} else {
			int a = g(num - 1);
			return h(a);
		}
	}


	public int h(int num) {
		if (num == 0) {
			return 0;
		} else if(num == 1) {
			return 1;
		} else {
			int a = h(num - 1);
			return f(a);
		}
	}

}
