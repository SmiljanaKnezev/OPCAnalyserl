package papter_tests;

public class Sum3 {

	public int sum(int a, int b) {
		int total = 0;
		if (a == b) {
			total = a + b;
		} else if(a > b) {
			total += a + sum(a - 1, b);
		} else {
			total += b + sum(b - 1, a);
		}
		return total;
	}

}
