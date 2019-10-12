package papter_tests;

public class Sum1 {

	public int sum(int a, int b) {
		int total = 0;
		if (a == b) {
			total = a + b;
		} else if(a > b) {
			while (a > b) {
				total += a;
				a --;
			}
			total += b;
		} else {
			while (b > a) {
				total += b;
				b--;
			}
			total += a;
		}
		return total;
	}

}
