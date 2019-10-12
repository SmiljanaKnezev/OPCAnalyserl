package papter_tests;

public class Sum2 {

	public int sum_maximum(int max, int min) {
		int sum_max = 0;
		while (max > min) {
			sum_max += max;
			max --;
		}
		sum_max += min;
		return sum_max;
	}

	public int sum(int a, int b) {
		int total = 0;
		if (a == b) {
			total = a + b;
		} else if (a > b) {
			total = sum_maximum(a, b);
		} else {
			total = sum_maximum(b, a);
		}
		return total;
	}

}
