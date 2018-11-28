import sys

class Distr():
    """
        Class to model coin distribution
        Model is consistent when totalRewards() ~= M
    """
    def __init__(self, N, M):
        self.N = N
        self.M = M
    
    def reward(self, x):
        N = self.N
        a = -99/(N**2 - 1)
        b = 100 - a
        return (a*x**2 + b) / (a*N*(N+1)*(2*N+1)/6 + b*N) * self.M

    def totalRewards(self):
        total = 0
        for i in range(self.N):
            total += self.reward(i+1)
        return total
    

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: {0} N M".format(sys.argv[0]))
        sys.exit(1)
    distr = Distr(int(sys.argv[1]), int(sys.argv[2]))
    print(distr.totalRewards())
