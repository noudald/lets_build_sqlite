describe "database" do
    def run_script(commands)
        raw_output = nil
        IO.popen("./db", "r+") do |pipe|
            commands.each do |command|
                pipe.puts command
            end

            pipe.close_write

            raw_output = pipe.gets(nil)
        end
        raw_output.split("\n")
    end

    it "inserts and retreives a row" do
        result = run_script([
            "insert 1 user1 person1@example.com",
            "select",
            ".exit"
        ])
        expect(result).to match_array([
            "sqlite> Executed successful.",
            "sqlite> (1, user1, person1@example.com)",
            "Executed successful.",
            "sqlite> "])
    end

    it "prints error message when table is full" do
        script = (1..1401).map do |i|
            "insert #{i} user#{i} person#{i}@test.com"
        end
        script << ".exit"
        result = run_script(script)
        expect(result[-2]).to eq("sqlite> Error: Table is full.")
    end

    it "allows inserting strings that are the maximum length" do
        long_username = "a" * 32
        long_email = "b" * 255
        script = [
            "insert 1 #{long_username} #{long_email}",
            "select",
            ".exit"
        ]
        result = run_script(script)
        expect(result).to match_array([
            "sqlite> Executed successful.",
            "sqlite> (1, #{long_username}, #{long_email})",
            "Executed successful.",
            "sqlite> "
        ])
    end

    it "prints error message if strings are too long" do
        long_username = "a" * 33
        long_email = "b" * 256
        script = [
            "insert 1 #{long_username} #{long_email}",
            "select",
            ".exit"
        ]
        result = run_script(script)
        expect(result).to match_array([
            "sqlite> String is too long.",
            "sqlite> Executed successful.",
            "sqlite> "
        ])
    end

    it "print an error message if id is negative" do
        script = [
            "insert -1 test foo@bar.com",
            "select",
            ".exit"
        ]
        result = run_script(script)
        expect(result).to match_array([
            "sqlite> ID must be positive.",
            "sqlite> Executed successful.",
            "sqlite> "
        ])
    end
end
